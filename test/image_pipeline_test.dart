import 'dart:typed_data';

import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/services/image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// A flat mid-grey image with one saturated patch, so brightness, contrast and
/// saturation each move something measurable.
Uint8List _sourceBytes({int width = 120, int height = 80}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(128, 128, 128));
  img.fillRect(image,
      x1: 0, y1: 0, x2: width ~/ 2, y2: height ~/ 2, color: img.ColorRgb8(200, 60, 40));
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  expect(decoded, isNotNull);
  return decoded!;
}

double _meanLuminance(img.Image image) {
  var total = 0.0;
  for (final pixel in image) {
    total += img.getLuminance(pixel);
  }
  return total / (image.width * image.height);
}

double _meanSaturation(img.Image image) {
  var total = 0.0;
  for (final pixel in image) {
    final r = pixel.r.toDouble(), g = pixel.g.toDouble(), b = pixel.b.toDouble();
    final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
    final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
    total += maxC == 0 ? 0 : (maxC - minC) / maxC;
  }
  return total / (image.width * image.height);
}

void main() {
  late Uint8List source;

  setUp(() => source = _sourceBytes());

  test('identity adjustments leave the image essentially untouched', () {
    final before = _meanLuminance(_decode(source));
    final after = _meanLuminance(_decode(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: EditState.initial),
    )));

    expect((after - before).abs(), lessThan(2), reason: 'only JPEG re-encoding differs');
  });

  test('positive brightness lightens, negative darkens', () {
    final base = _meanLuminance(_decode(source));

    final lighter = _meanLuminance(_decode(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(brightness: 60))),
    )));
    final darker = _meanLuminance(_decode(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(brightness: -60))),
    )));

    expect(lighter, greaterThan(base + 5));
    expect(darker, lessThan(base - 5));
  });

  test('saturation pushes colour away from and toward grey', () {
    final base = _meanSaturation(_decode(source));

    final vivid = _meanSaturation(_decode(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(saturation: 80))),
    )));
    final muted = _meanSaturation(_decode(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(saturation: -80))),
    )));

    expect(vivid, greaterThan(base));
    expect(muted, lessThan(base));
  });

  test('contrast changes the spread of luminance', () {
    double spread(Uint8List bytes) {
      final image = _decode(bytes);
      var min = 255.0, max = 0.0;
      for (final pixel in image) {
        final l = img.getLuminance(pixel).toDouble();
        if (l < min) min = l;
        if (l > max) max = l;
      }
      return max - min;
    }

    final base = spread(source);
    final punchy = spread(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(contrast: 90))),
    ));
    final flat = spread(ImagePipeline.renderSync(
      RenderRequest(bytes: source, state: const EditState(adjust: AdjustParams(contrast: -90))),
    ));

    expect(punchy, greaterThan(base));
    expect(flat, lessThan(base));
  });

  test('sharpness runs in both directions without throwing', () {
    for (final value in [-100.0, -40.0, 40.0, 100.0]) {
      final out = ImagePipeline.renderSync(
        RenderRequest(bytes: source, state: EditState(adjust: AdjustParams(sharpness: value))),
      );
      final image = _decode(out);
      expect(image.width, 120, reason: 'sharpness must not resize');
      expect(image.height, 80);
    }
  });

  test('maxEdge downsizes while preserving aspect ratio', () {
    final out = _decode(ImagePipeline.renderSync(RenderRequest(
      bytes: _sourceBytes(width: 1000, height: 500),
      state: EditState.initial,
      maxEdge: 200,
    )));

    expect(out.width, 200);
    expect(out.height, 100);
  });

  test('maxEdge never upscales a smaller image', () {
    final out = _decode(ImagePipeline.renderSync(RenderRequest(
      bytes: source,
      state: EditState.initial,
      maxEdge: 4000,
    )));

    expect(out.width, 120);
    expect(out.height, 80);
  });

  test('buildPreviewSource caps the longest edge', () {
    final out = _decode(ImagePipeline.buildPreviewSourceSync(
      _sourceBytes(width: 4000, height: 3000),
    ));

    expect(out.width, ImagePipeline.previewMaxEdge);
    expect(out.height, (ImagePipeline.previewMaxEdge * 3 / 4).round());
  });

  test('a corrupted file fails with a message meant for the user', () {
    expect(
      () => ImagePipeline.renderSync(RenderRequest(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        state: EditState.initial,
      )),
      throwsA(isA<ImagePipelineFailure>()),
    );
  });

  test('neutral sliders produce the identity colour matrix', () {
    expect(ImagePipeline.isIdentityMatrix(ImagePipeline.colorMatrix(AdjustParams.identity)), isTrue);
    expect(ImagePipeline.isIdentityMatrix(ImagePipeline.colorMatrix(const AdjustParams(sharpness: 50))), isTrue,
        reason: 'sharpness is spatial and must stay out of the colour matrix');
    expect(ImagePipeline.isIdentityMatrix(ImagePipeline.colorMatrix(const AdjustParams(brightness: 1))), isFalse);
  });

  test('full saturation cut leaves pure grey', () {
    final image = img.Image(width: 1, height: 1)..setPixelRgb(0, 0, 200, 40, 90);
    final out = ImagePipeline.applyColorMatrix(image, ImagePipeline.colorMatrix(const AdjustParams(saturation: -100)));
    final p = out.getPixel(0, 0);
    expect(p.r, p.g);
    expect(p.g, p.b);
  });

  test('export matches the canvas: sharpness base then the same colour matrix', () {
    const params = AdjustParams(brightness: 30, contrast: 25, saturation: -20, sharpness: 40);
    const state = EditState(adjust: params);
    final exported = _decode(
        ImagePipeline.renderSync(RenderRequest(bytes: source, state: state, quality: 100)));

    final base = ImagePipeline.applySharpness(_decode(source), params.sharpness);
    final shown =
        ImagePipeline.applyColorMatrix(base, ImagePipeline.colorMatrixFor(state));

    expect((_meanLuminance(exported) - _meanLuminance(shown)).abs(), lessThan(1.5));
  });
}
