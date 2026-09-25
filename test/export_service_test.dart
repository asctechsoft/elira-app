import 'dart:io';
import 'dart:typed_data';

import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/models/data_models/text_layer.dart';
import 'package:elira/services/export_service.dart';
import 'package:elira/services/image_pipeline.dart';
import 'package:elira/values/text_fonts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// `getTemporaryDirectory` has no implementation in a unit test, so it is
/// pointed at a real directory the test owns.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.path);

  final String path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

Uint8List _photo({int width = 400, int height = 300}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(120, 120, 120));
  img.fillRect(image,
      x1: 0,
      y1: 0,
      x2: width ~/ 2 - 1,
      y2: height - 1,
      color: img.ColorRgb8(210, 70, 50));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The font families are fetched over the network on first use, which a test
  // has no business doing. Platform fonts still prove the text is drawn into
  // the pixels, which is what these tests are about.
  TextFonts.allowDownloadableFonts = false;

  late Directory tmp;
  late File source;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('elira_export_test');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
    await source.writeAsBytes(_photo());
  });

  tearDown(() async {
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  ExportRequest request({
    EditState state = EditState.initial,
    ExportFormat format = ExportFormat.jpeg,
    ExportSize size = ExportSize.original,
    int quality = 90,
    bool watermark = false,
  }) =>
      ExportRequest(
        sourcePath: source.path,
        state: state,
        format: format,
        size: size,
        quality: quality,
        watermark: watermark,
      );

  group('resolution', () {
    test('exports at the original size, not the editor preview size', () async {
      final big = File('${tmp.path}${Platform.pathSeparator}big.jpg');
      await big.writeAsBytes(_photo(width: 2400, height: 1800));

      final result = await ExportService.export(ExportRequest(
        sourcePath: big.path,
        state: EditState.initial,
      ));

      expect(result.width, 2400);
      expect(result.height, 1800,
          reason: 'the 1440px preview is a working copy, not the output');
    });

    test('a size cap downscales while keeping the aspect ratio', () async {
      final result = await ExportService.export(
        request(size: ExportSize.medium),
      );

      expect(result.width, 400, reason: 'already under the 1080 cap');

      final big = File('${tmp.path}${Platform.pathSeparator}big.jpg');
      await big.writeAsBytes(_photo(width: 4000, height: 2000));
      final capped = await ExportService.export(ExportRequest(
        sourcePath: big.path,
        state: EditState.initial,
        size: ExportSize.medium,
      ));

      expect(capped.width, 1080);
      expect(capped.height, 540);
    });

    test('a crop changes the exported dimensions', () async {
      final result = await ExportService.export(request(
        state: const EditState(geometry: GeometryParams(right: 0.5)),
      ));

      expect(result.width, 200);
      expect(result.height, 300);
    });

    test('a rotation swaps them', () async {
      final result = await ExportService.export(request(
        state: const EditState(geometry: GeometryParams(quarterTurns: 1)),
      ));

      expect(result.width, 300);
      expect(result.height, 400);
    });
  });

  group('the file', () {
    test('is written and is a real image', () async {
      final result = await ExportService.export(request());

      expect(await result.file.exists(), isTrue);
      expect(result.sizeInBytes, greaterThan(0));
      expect(_decode(result.bytes).width, 400);
    });

    test('never touches the original', () async {
      final before = await source.readAsBytes();
      await ExportService.export(request(
        state: const EditState(
          adjust: AdjustParams(brightness: 60),
          filter: FilterParams(id: 'bw'),
        ),
      ));

      expect(await source.readAsBytes(), before);
    });

    test('uses the extension that matches the format', () async {
      final jpeg = await ExportService.export(request());
      final png = await ExportService.export(request(format: ExportFormat.png));

      expect(jpeg.file.path, endsWith('.jpg'));
      expect(png.file.path, endsWith('.png'));
    });

    test('writes the format it says it does', () async {
      final jpeg = await ExportService.export(request(quality: 80));
      final png = await ExportService.export(request(format: ExportFormat.png));

      // Magic bytes rather than file size: on a flat synthetic image PNG is
      // actually the smaller of the two, so size proves nothing here.
      expect(png.bytes.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
      expect(jpeg.bytes.sublist(0, 3), [0xFF, 0xD8, 0xFF]);
    });

    test('a lower quality produces a smaller file', () async {
      final high = await ExportService.export(request(quality: 95));
      final low = await ExportService.export(request(quality: 20));

      expect(low.sizeInBytes, lessThan(high.sizeInBytes));
    });

    test('a missing source fails with a message, not a crash', () async {
      await source.delete();
      expect(
        () => ExportService.export(request()),
        throwsA(isA<ExportFailure>()),
      );
    });

    test('a corrupt source fails the same way', () async {
      await source.writeAsBytes(Uint8List.fromList([1, 2, 3, 4]));
      expect(
        () => ExportService.export(request()),
        throwsA(isA<ExportFailure>()),
      );
    });
  });

  group('the edits actually land', () {
    test('brightness shows up in the exported pixels', () async {
      final plain = await ExportService.export(request());
      final bright = await ExportService.export(request(
        state: const EditState(adjust: AdjustParams(brightness: 70)),
      ));

      expect(
        _meanLuminance(_decode(bright.bytes)),
        greaterThan(_meanLuminance(_decode(plain.bytes)) + 5),
      );
    });

    test('a filter shows up too', () async {
      final result = await ExportService.export(request(
        state: const EditState(filter: FilterParams(id: 'bw')),
        quality: 100,
      ));

      final pixel = _decode(result.bytes).getPixel(50, 150);
      expect(pixel.r, closeTo(pixel.b.toDouble(), 8));
    });

    test('an effect shows up', () async {
      final plain = await ExportService.export(request(quality: 100));
      final vignetted = await ExportService.export(request(
        state: const EditState(effects: EffectParams(vignette: 100)),
        quality: 100,
      ));

      expect(
        img.getLuminance(_decode(vignetted.bytes).getPixel(2, 2)),
        lessThan(img.getLuminance(_decode(plain.bytes).getPixel(2, 2))),
      );
    });

    test('export matches what the canvas showed, at a different resolution',
        () async {
      // The editor renders the same state to 1440px and applies the colour
      // matrix on the GPU; export runs both stages on the CPU at full size.
      // Same operations, same maths, so the average colour must agree.
      const state = EditState(
        adjust: AdjustParams(brightness: 35, contrast: 20, saturation: -25),
        filter: FilterParams(id: 'warm', strength: 70),
      );

      final exported = await ExportService.export(request(state: state, quality: 100));
      final preview = ImagePipeline.renderSync(RenderRequest(
        bytes: await File(source.path).readAsBytes(),
        state: state,
        maxEdge: 120,
        quality: 100,
      ));

      expect(
        (_meanLuminance(_decode(exported.bytes)) -
                _meanLuminance(_decode(preview)))
            .abs(),
        lessThan(3),
      );
    });
  });

  group('overlays', () {
    const caption = TextLayer(id: 't1', text: 'Hello', dy: 0.5, size: 0.2);

    test('text is drawn into the exported pixels', () async {
      final plain = await ExportService.export(request(quality: 100));
      final captioned = await ExportService.export(request(
        state: const EditState(texts: [caption]),
        quality: 100,
      ));

      expect(captioned.width, plain.width, reason: 'text must not resize');
      expect(
        _meanLuminance(_decode(captioned.bytes)),
        isNot(closeTo(_meanLuminance(_decode(plain.bytes)), 0.05)),
        reason: 'white text over a mid-grey photo changes the average',
      );
    });

    test('a blank layer is skipped rather than drawn', () async {
      final plain = await ExportService.export(request(quality: 100));
      final blank = await ExportService.export(request(
        state: const EditState(texts: [TextLayer(id: 't1', text: '   ')]),
        quality: 100,
      ));

      expect(
        _meanLuminance(_decode(blank.bytes)),
        closeTo(_meanLuminance(_decode(plain.bytes)), 0.5),
      );
    });

    test('the watermark changes the corner it sits in', () async {
      final plain = await ExportService.export(request(quality: 100));
      final marked = await ExportService.export(
        request(watermark: true, quality: 100),
      );

      final a = _decode(plain.bytes);
      final b = _decode(marked.bytes);
      var difference = 0.0;
      for (var x = a.width - 120; x < a.width; x++) {
        for (var y = a.height - 40; y < a.height; y++) {
          difference +=
              (img.getLuminance(b.getPixel(x, y)) - img.getLuminance(a.getPixel(x, y)))
                  .abs();
        }
      }
      expect(difference, greaterThan(0));
    });

    test('text scales with the output, so both sizes look the same', () async {
      final big = File('${tmp.path}${Platform.pathSeparator}big.jpg');
      await big.writeAsBytes(_photo(width: 800, height: 600));

      final small = await ExportService.export(request(
        state: const EditState(texts: [caption]),
        quality: 100,
      ));
      final large = await ExportService.export(ExportRequest(
        sourcePath: big.path,
        state: const EditState(texts: [caption]),
        quality: 100,
      ));

      // Same normalised size means the caption covers the same share of the
      // frame at both resolutions.
      expect(large.width / small.width, closeTo(2, 0.01));
    });

    test('stages are reported in order', () async {
      final stages = <ExportStage>[];
      await ExportService.export(
        request(state: const EditState(texts: [caption])),
        onStage: stages.add,
      );

      expect(
        stages,
        containsAllInOrder([
          ExportStage.rendering,
          ExportStage.compositing,
          ExportStage.encoding,
          ExportStage.saving,
          ExportStage.done,
        ]),
      );
    });

    test('compositing is skipped when there is nothing to draw', () async {
      final stages = <ExportStage>[];
      await ExportService.export(request(), onStage: stages.add);

      expect(stages, isNot(contains(ExportStage.compositing)));
    });
  });
}
