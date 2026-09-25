import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import '../models/data_models/edit_operation.dart';
import '../models/data_models/text_layer.dart';
import '../values/text_fonts.dart';
import 'image_pipeline.dart';

enum ExportFormat { jpeg, png }

/// Output size. "Original" is the whole point of a non-destructive editor:
/// every edit was made against a 1440px preview and is replayed here at the
/// photo's real resolution.
enum ExportSize { original, large, medium }

extension ExportSizeX on ExportSize {
  /// Null means no downscale at all.
  int? get maxEdge => switch (this) {
        ExportSize.original => null,
        ExportSize.large => 2048,
        ExportSize.medium => 1080,
      };

  String get label => switch (this) {
        ExportSize.original => 'Original',
        ExportSize.large => 'Large · 2048 px',
        ExportSize.medium => 'Medium · 1080 px',
      };
}

/// Which part of the work is running, so the UI can say something true rather
/// than spin a generic indicator.
enum ExportStage { rendering, compositing, encoding, saving, done }

class ExportRequest {
  const ExportRequest({
    required this.sourcePath,
    required this.state,
    this.format = ExportFormat.jpeg,
    this.quality = 90,
    this.size = ExportSize.original,
    this.watermark = false,
  });

  final String sourcePath;
  final EditState state;
  final ExportFormat format;
  final int quality;
  final ExportSize size;
  final bool watermark;

  bool get isPng => format == ExportFormat.png;
}

class ExportResult {
  const ExportResult({
    required this.file,
    required this.bytes,
    required this.width,
    required this.height,
  });

  final File file;
  final Uint8List bytes;
  final int width;
  final int height;

  int get sizeInBytes => bytes.lengthInBytes;

  String get resolutionLabel => '$width × $height';

  String get fileSizeLabel {
    final mb = sizeInBytes / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    return '${(sizeInBytes / 1024).round()} KB';
  }
}

class ExportFailure implements Exception {
  const ExportFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Replays the edit stack at full resolution and writes a file.
///
/// The editor works on a 1440px preview (spec 7/23); this is the one place
/// that runs the same operations against the real pixels. Anything that looks
/// different here from what the canvas showed is a bug, which is why both use
/// the same [ImagePipeline] stages and the same colour matrix.
class ExportService {
  const ExportService._();

  static Future<ExportResult> export(
    ExportRequest request, {
    void Function(ExportStage stage)? onStage,
  }) async {
    final source = File(request.sourcePath);
    if (!await source.exists()) {
      throw const ExportFailure('The photo could not be found.');
    }

    onStage?.call(ExportStage.rendering);
    final original = await source.readAsBytes();

    RawPixels pixels;
    try {
      pixels = await ImagePipeline.renderRaw(RenderRequest(
        bytes: original,
        state: request.state,
        maxEdge: request.size.maxEdge,
      ));
    } on ImagePipelineFailure catch (failure) {
      throw ExportFailure(failure.message);
    }

    final overlays = request.state.texts.where((l) => !l.isBlank).toList();
    if (overlays.isNotEmpty || request.watermark) {
      onStage?.call(ExportStage.compositing);
      pixels = await _drawOverlays(
        pixels,
        texts: overlays,
        watermark: request.watermark,
      );
    }

    onStage?.call(ExportStage.encoding);
    final bytes = await ImagePipeline.encode(
      pixels,
      png: request.isPng,
      quality: request.quality,
    );

    onStage?.call(ExportStage.saving);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${dir.path}${Platform.pathSeparator}elira_$stamp.${request.isPng ? 'png' : 'jpg'}',
    );
    await file.writeAsBytes(bytes, flush: true);

    onStage?.call(ExportStage.done);
    return ExportResult(
      file: file,
      bytes: bytes,
      width: pixels.width,
      height: pixels.height,
    );
  }

  /// Draws the text layers and the watermark.
  ///
  /// This runs on the main isolate, unlike every other stage, because
  /// `TextPainter` needs the Flutter engine and `dart:ui` handles cannot cross
  /// an isolate boundary. Using the same painter as the editor overlay — and
  /// the same [TextFonts] catalogue — is what makes the exported caption match
  /// what was on screen instead of being an approximation drawn with a bitmap
  /// font.
  static Future<RawPixels> _drawOverlays(
    RawPixels pixels, {
    required List<TextLayer> texts,
    required bool watermark,
  }) async {
    // The fonts are fetched at runtime, and google_fonts starts that fetch as
    // a side effect of building a style rather than returning a future. Build
    // every style we are about to use, then wait for those loads to settle:
    // painting first would quietly draw the caption in the platform fallback
    // font, which is not what the editor showed. A failed fetch is caught so
    // the export still produces a file.
    for (final layer in texts) {
      TextFonts.byId(layer.fontId)
          .style(fontSize: 12, color: const Color(0xFFFFFFFF));
    }
    if (watermark) {
      TextFonts.byId(TextLayer.defaultFontId)
          .style(fontSize: 12, color: const Color(0xFFFFFFFF));
    }
    try {
      await GoogleFonts.pendingFonts();
    } catch (error) {
      debugPrint('[export] font load failed, drawing with the fallback: $error');
    }

    final base = await _toUiImage(pixels);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImage(base, Offset.zero, Paint());

    final width = pixels.width.toDouble();
    final height = pixels.height.toDouble();

    for (final layer in texts) {
      _paintLayer(canvas, layer, width, height);
    }
    if (watermark) _paintWatermark(canvas, width, height);

    final picture = recorder.endRecording();
    final composited = await picture.toImage(pixels.width, pixels.height);
    final data =
        await composited.toByteData(format: ui.ImageByteFormat.rawRgba);

    base.dispose();
    picture.dispose();
    composited.dispose();

    if (data == null) {
      throw const ExportFailure('Could not draw the text onto the photo.');
    }
    return RawPixels(
      rgba: data.buffer.asUint8List(),
      width: pixels.width,
      height: pixels.height,
    );
  }

  /// Mirrors `TextOverlay`: the layer is laid out across the full frame width
  /// and anchored by its centre, so the same normalised position lands in the
  /// same place whatever the resolution.
  static void _paintLayer(
    Canvas canvas,
    TextLayer layer,
    double width,
    double height,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: layer.text,
        style: TextFonts.byId(layer.fontId).style(
          fontSize: layer.size * height,
          color: Color(layer.color),
        ),
      ),
      textAlign: textAlignOf(layer.align),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    painter.paint(
      canvas,
      Offset(
        layer.dx * width - width / 2,
        layer.dy * height - painter.height / 2,
      ),
    );
  }

  static void _paintWatermark(Canvas canvas, double width, double height) {
    // Scaled off the image, not a fixed pixel size, so it is the same relative
    // size on a 1080px export and on a 6000px one.
    final fontSize = height * 0.028;
    final painter = TextPainter(
      text: TextSpan(
        text: 'ASC Photo AI',
        style: TextFonts.byId(TextLayer.defaultFontId).style(
          fontSize: fontSize,
          color: const Color(0xE6FFFFFF),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final margin = height * 0.025;
    painter.paint(
      canvas,
      Offset(width - painter.width - margin, height - painter.height - margin),
    );
  }

  static Future<ui.Image> _toUiImage(RawPixels pixels) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels.rgba,
      pixels.width,
      pixels.height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }
}
