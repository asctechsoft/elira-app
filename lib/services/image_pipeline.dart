import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/data_models/edit_operation.dart';
import 'color_matrix.dart';
import 'photo_filters.dart';

/// Decoded pixels on their way between stages.
///
/// Export needs an exit point *before* encoding: text is drawn with Flutter's
/// own `TextPainter`, which needs the engine and therefore cannot run inside
/// the isolate that does the pixel work. So the isolate hands back raw RGBA,
/// the main isolate draws the overlays, and a second isolate call encodes.
class RawPixels {
  const RawPixels({
    required this.rgba,
    required this.width,
    required this.height,
  });

  final Uint8List rgba;
  final int width;
  final int height;

  int get pixelCount => width * height;
}

/// Immutable input to a render. Kept to plain data so it can cross an isolate
/// boundary without any copying surprises.
class RenderRequest {
  const RenderRequest({
    required this.bytes,
    required this.state,
    this.maxEdge,
    this.quality = 92,
  });

  final Uint8List bytes;
  final EditState state;

  /// Longest edge of the output. Null renders at the source resolution, which
  /// is what export uses; the editor always passes a preview-sized value.
  final int? maxEdge;

  final int quality;
}

/// All pixel work happens here. Nothing in this file touches Flutter, so it is
/// safe to run in a background isolate and is directly unit-testable.
///
/// The pipeline has three stages, in this order:
///   1. geometry — rotate, flip, crop (CPU, changes dimensions)
///   2. spatial  — sharpness, blur, glow, vignette, grain (CPU, neighbourhood)
///   3. colour   — one composed 4x5 matrix (GPU in the editor, CPU on export)
///
/// The editor renders stages 1 and 2 and caches the result, then hands stage 3
/// to the canvas as a `ColorFilter`. That is why dragging a colour slider or
/// picking a filter costs no image processing at all.
class ImagePipeline {
  const ImagePipeline._();

  /// Longest edge of the editor preview. Spec 7 and 23: the canvas renders at
  /// a reduced resolution while editing, and only export replays the stack at
  /// full size. Re-rendering a 48MP image on every slider tick is what makes
  /// naive editors drop frames.
  static const int previewMaxEdge = 1440;

  /// Longest edge of a history-strip entry.
  static const int thumbnailMaxEdge = 160;

  /// Longest edge of a filter-strip swatch.
  static const int swatchMaxEdge = 96;

  /// Mean luminance Auto treats as "dark enough to need lifting".
  static const double _exposureFloor = 104;

  // ----------------------------------------------------------- entry points

  /// Stages 1 and 2 only: what the editor canvas draws under its colour
  /// filter. Returns the source untouched when there is no spatial work, which
  /// is the common case while someone is only moving colour sliders.
  static Future<Uint8List> renderSpatial(Uint8List source, EditState state) {
    if (state.isSpatialIdentity) return Future.value(source);
    return Isolate.run(() => renderSpatialSync(source, state));
  }

  static Uint8List renderSpatialSync(Uint8List source, EditState state) {
    if (state.isSpatialIdentity) return source;
    final image = _spatial(applyGeometry(_decode(source), state.geometry), state);
    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  static Future<Uint8List> render(RenderRequest request) =>
      Isolate.run(() => renderSync(request));

  /// All three stages, stopping short of encoding.
  static RawPixels renderRawSync(RenderRequest request) {
    var image = applyGeometry(_decode(request.bytes), request.state.geometry);
    image = _fit(image, request.maxEdge);
    image = _spatial(image, request.state);
    image = applyColorMatrix(image, colorMatrixFor(request.state));
    return RawPixels(
      rgba: image.getBytes(order: img.ChannelOrder.rgba),
      width: image.width,
      height: image.height,
    );
  }

  static Future<RawPixels> renderRaw(RenderRequest request) =>
      Isolate.run(() => renderRawSync(request));

  static Uint8List encodeSync(
    RawPixels pixels, {
    required bool png,
    int quality = 92,
  }) {
    final image = img.Image.fromBytes(
      width: pixels.width,
      height: pixels.height,
      bytes: pixels.rgba.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
    return Uint8List.fromList(
      // PNG is lossless, so the quality slider does not apply to it; pretending
      // otherwise in the UI would be a control that does nothing.
      png ? img.encodePng(image) : img.encodeJpg(image, quality: quality),
    );
  }

  static Future<Uint8List> encode(
    RawPixels pixels, {
    required bool png,
    int quality = 92,
  }) =>
      Isolate.run(() => encodeSync(pixels, png: png, quality: quality));

  /// All three stages. Used for history thumbnails, filter swatches and — with
  /// a null [RenderRequest.maxEdge] — export.
  static Uint8List renderSync(RenderRequest request) {
    var image = applyGeometry(_decode(request.bytes), request.state.geometry);
    image = _fit(image, request.maxEdge);
    image = _spatial(image, request.state);
    image = applyColorMatrix(image, colorMatrixFor(request.state));
    return Uint8List.fromList(img.encodeJpg(image, quality: request.quality));
  }

  /// Produces the downscaled working copy the editor renders from. Decoding a
  /// full-resolution original on every tick would dominate the frame budget,
  /// so it is done once and the result is reused.
  static Uint8List buildPreviewSourceSync(
    Uint8List originalBytes, {
    int maxEdge = previewMaxEdge,
  }) {
    final decoded = _decode(originalBytes);
    return Uint8List.fromList(img.encodeJpg(_fit(decoded, maxEdge), quality: 92));
  }

  static Future<Uint8List> buildPreviewSource(
    Uint8List originalBytes, {
    int maxEdge = previewMaxEdge,
  }) =>
      Isolate.run(() => buildPreviewSourceSync(originalBytes, maxEdge: maxEdge));

  /// `decodeImage` does not merely return null on bad input: probing a
  /// truncated file can throw out of a format detector. Both paths have to
  /// become the same user-facing failure (spec 30: corrupted/unsupported file).
  static img.Image _decode(Uint8List bytes) {
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      decoded = null;
    }
    if (decoded == null) {
      throw const ImagePipelineFailure('Unsupported or corrupted image file.');
    }
    return decoded;
  }

  // -------------------------------------------------------- stage 1: geometry

  /// Rotate, then mirror, then crop — the order the crop UI implies, because
  /// the rectangle the user drags is in the already-rotated view.
  static img.Image applyGeometry(img.Image src, GeometryParams g) {
    if (g.isIdentity) return src;

    var out = src;
    if (g.quarterTurns % 4 != 0) {
      out = img.copyRotate(out, angle: (g.quarterTurns % 4) * 90);
    }
    if (g.flipH && g.flipV) {
      out = img.flipHorizontalVertical(out);
    } else if (g.flipH) {
      out = img.flipHorizontal(out);
    } else if (g.flipV) {
      out = img.flipVertical(out);
    }

    if (g.hasCrop) {
      final x = (g.left * out.width).round().clamp(0, out.width - 1);
      final y = (g.top * out.height).round().clamp(0, out.height - 1);
      final w = (g.cropWidth * out.width).round().clamp(1, out.width - x);
      final h = (g.cropHeight * out.height).round().clamp(1, out.height - y);
      out = img.copyCrop(out, x: x, y: y, width: w, height: h);
    }
    return out;
  }

  // --------------------------------------------------------- stage 2: spatial

  static img.Image _spatial(img.Image image, EditState state) {
    // Neighbourhood radii are in pixels, so the same slider value would look
    // far weaker on a 6000px export than on the 1440px preview. Scaling by the
    // resolution ratio is what keeps an export faithful to what was shown.
    final longest = math.max(image.width, image.height);
    final scale = (longest / previewMaxEdge).clamp(0.25, 8.0);

    var out = applySharpness(image, state.adjust.sharpness, scale: scale);
    out = applyEffects(out, state.effects, scale: scale);
    return out;
  }

  static img.Image applySharpness(
    img.Image image,
    double sharpness, {
    double scale = 1,
  }) {
    if (sharpness > 0) {
      return img.convolution(
        image,
        filter: const [0, -1, 0, -1, 5, -1, 0, -1, 0],
        amount: (sharpness / 100).clamp(0.0, 1.0),
      );
    }
    if (sharpness < 0) {
      // Negative sharpness softens, so the single slider covers both
      // directions the way the design's one "Sharpness" control implies.
      return img.gaussianBlur(image, radius: _radius(-sharpness, 4, scale));
    }
    return image;
  }

  static img.Image applyEffects(
    img.Image image,
    EffectParams e, {
    double scale = 1,
  }) {
    if (e.isIdentity) return image;
    var out = image;

    if (e.blur > 0) {
      out = img.gaussianBlur(out, radius: _radius(e.blur, 12, scale));
    }

    if (e.glow > 0) {
      // Bloom: a darkened, blurred copy screen-blended back on top. Screen
      // only ever lightens, so highlights bloom while shadows stay put.
      final amount = (e.glow / 100).clamp(0.0, 1.0);
      final layer = img.gaussianBlur(out.clone(), radius: _radius(60, 10, scale));
      img.adjustColor(layer, brightness: 0.25 + 0.45 * amount, contrast: 1.1);
      out = img.compositeImage(out, layer, blend: img.BlendMode.screen);
    }

    if (e.vignette > 0) {
      out = img.vignette(
        out,
        start: 0.35,
        end: 0.95,
        amount: (e.vignette / 100).clamp(0.0, 1.0),
      );
    }

    if (e.grain > 0) {
      // Grain last, so it is never blurred by the stages above.
      out = img.noise(out, (e.grain / 100) * 32, type: img.NoiseType.gaussian);
    }

    return out;
  }

  static int _radius(double value, int maxRadius, double scale) =>
      ((value / 100) * maxRadius * scale).round().clamp(1, 64);

  // ---------------------------------------------------------- stage 3: colour

  /// The Adjust sliders as one matrix: brightness, then contrast, then
  /// saturation.
  static List<double> colorMatrix(AdjustParams p) => ColorMatrix.composeAll([
        ColorMatrix.contrast(_scale(p.contrast, 0.5)),
        ColorMatrix.brightness(_scale(p.brightness, 0.5)),
        ColorMatrix.saturation(_scale(p.saturation, 1.0)),
      ]);

  /// The single matrix the canvas applies: the chosen look first, then the
  /// user's own corrections on top of it.
  static List<double> colorMatrixFor(EditState state) => ColorMatrix.compose(
        colorMatrix(state.adjust),
        PhotoFilters.matrixFor(state.filter),
      );

  static bool isIdentityMatrix(List<double> m) => ColorMatrix.isIdentity(m);

  static img.Image applyColorMatrix(img.Image image, List<double> m) {
    if (ColorMatrix.isIdentity(m)) return image;
    for (final px in image) {
      final r = px.rNormalized * 255;
      final g = px.gNormalized * 255;
      final b = px.bNormalized * 255;
      px
        ..rNormalized = ((m[0] * r + m[1] * g + m[2] * b + m[4]) / 255).clamp(0.0, 1.0)
        ..gNormalized = ((m[5] * r + m[6] * g + m[7] * b + m[9]) / 255).clamp(0.0, 1.0)
        ..bNormalized = ((m[10] * r + m[11] * g + m[12] * b + m[14]) / 255).clamp(0.0, 1.0);
    }
    return image;
  }

  /// -100..100 -> (1 - span)..(1 + span), with 0 mapping to exactly 1.0.
  static double _scale(double value, double span) =>
      1.0 + (value.clamp(-100.0, 100.0) / 100.0) * span;

  // ------------------------------------------------------------------- auto

  static Future<AdjustParams> autoAdjust(Uint8List bytes) =>
      Isolate.run(() => autoAdjustSync(bytes));

  /// Derives Brightness/Contrast/Saturation from the image itself, in the same
  /// -100..100 slider space the panel uses — so Auto lands on the sliders and
  /// stays editable rather than being an opaque one-way button.
  ///
  /// Contrast stretches the 0.5th..99.5th luminance percentiles toward the
  /// full range. Percentiles rather than min/max: one blown highlight or one
  /// dead pixel must not decide the whole correction. Brightness then
  /// re-centres the mean, and saturation is nudged only when the image is
  /// genuinely flat, so Auto on an already-vivid photo leaves it alone.
  static AdjustParams autoAdjustSync(Uint8List bytes) {
    final image = _decode(bytes);

    final histogram = List<int>.filled(256, 0);
    var lumaSum = 0.0;
    var satSum = 0.0;
    var count = 0;

    for (final px in image) {
      final r = px.rNormalized * 255;
      final g = px.gNormalized * 255;
      final b = px.bNormalized * 255;
      final luma =
          ColorMatrix.lumaR * r + ColorMatrix.lumaG * g + ColorMatrix.lumaB * b;
      histogram[luma.round().clamp(0, 255)]++;
      lumaSum += luma;

      final maxC = math.max(r, math.max(g, b));
      final minC = math.min(r, math.min(g, b));
      satSum += maxC <= 0 ? 0 : (maxC - minC) / maxC;
      count++;
    }

    if (count == 0) return AdjustParams.identity;

    final cut = (count * 0.005).round();
    final low = _percentile(histogram, cut).toDouble();
    final high = _percentile(histogram, count - 1 - cut).toDouble();
    final meanLuma = lumaSum / count;
    final meanSat = satSum / count;

    // Contrast that would map [low, high] onto the full range. It is only a
    // request: exposure wins where the two compete, below.
    final span = (high - low).clamp(1.0, 255.0);
    final wanted = (255 / span).clamp(1.0, 1.5);

    // The canvas applies brightness first and contrast second, pivoting about
    // mid-grey, so the two are not independent: on a dark photo, contrast
    // pulls the mean *down* faster than the brightness range can lift it. Ask
    // for the full contrast, then back it off until the exposure lands — a
    // correctly exposed photo is worth more than a punchy one.
    var contrastMul = 1.0;
    var brightnessMul = 1.0;
    const steps = 10;
    for (var i = 0; i <= steps; i++) {
      final c = wanted - (wanted - 1.0) * (i / steps);
      final pivot = 127.5 * (1 - c);
      final neutralMean = c * meanLuma + pivot;

      // A well-exposed photo is left alone. Without this dead zone Auto would
      // nudge the brightness of every image, including the ones that were
      // already right, which is how an auto button loses the user's trust.
      final b = neutralMean >= _exposureFloor && neutralMean <= 148
          ? 1.0
          : ((126.0 - pivot) / (c * math.max(meanLuma, 1))).clamp(0.5, 1.5);

      contrastMul = c;
      brightnessMul = b;
      if (c * b * meanLuma + pivot >= _exposureFloor || i == steps) break;
    }

    final saturationMul = meanSat >= 0.30
        ? 1.0
        : (0.30 / math.max(meanSat, 0.05)).clamp(1.0, 1.35);

    return AdjustParams(
      brightness: _toSlider(brightnessMul, 0.5),
      contrast: _toSlider(contrastMul, 0.5),
      saturation: _toSlider(saturationMul, 1.0),
    );
  }

  static int _percentile(List<int> histogram, int target) {
    var running = 0;
    for (var i = 0; i < histogram.length; i++) {
      running += histogram[i];
      if (running > target) return i;
    }
    return 255;
  }

  /// Inverse of [_scale]: multiplier back to the -100..100 the sliders show.
  static double _toSlider(double multiplier, double span) =>
      (((multiplier - 1.0) / span) * 100).clamp(-100.0, 100.0).roundToDouble();

  // ------------------------------------------------------------------ utils

  static img.Image _fit(img.Image src, int? maxEdge) {
    if (maxEdge == null) return src;
    final longest = src.width > src.height ? src.width : src.height;
    if (longest <= maxEdge) return src;
    return src.width >= src.height
        ? img.copyResize(src, width: maxEdge, interpolation: img.Interpolation.average)
        : img.copyResize(src, height: maxEdge, interpolation: img.Interpolation.average);
  }
}

class ImagePipelineFailure implements Exception {
  const ImagePipelineFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
