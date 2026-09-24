import 'dart:typed_data';

import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/services/image_pipeline.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

img.Image _decode(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  expect(decoded, isNotNull);
  return decoded!;
}

Uint8List _encode(img.Image image) =>
    Uint8List.fromList(img.encodeJpg(image, quality: 100));

/// Left half red, right half blue — so a horizontal flip is measurable.
Uint8List _halves({int width = 120, int height = 80}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(30, 30, 200));
  img.fillRect(image,
      x1: 0, y1: 0, x2: width ~/ 2 - 1, y2: height - 1,
      color: img.ColorRgb8(200, 30, 30));
  return _encode(image);
}

/// A vertical luminance ramp between [low] and [high].
Uint8List _ramp({int low = 0, int high = 255, int width = 80, int height = 80}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    final v = (low + (high - low) * (y / (height - 1))).round();
    img.fillRect(image, x1: 0, y1: y, x2: width - 1, y2: y,
        color: img.ColorRgb8(v, v, v));
  }
  return _encode(image);
}

double _meanLuminance(img.Image image) {
  var total = 0.0;
  for (final pixel in image) {
    total += img.getLuminance(pixel);
  }
  return total / (image.width * image.height);
}

double _variance(img.Image image) {
  final mean = _meanLuminance(image);
  var total = 0.0;
  for (final pixel in image) {
    final d = img.getLuminance(pixel) - mean;
    total += d * d;
  }
  return total / (image.width * image.height);
}

void main() {
  group('geometry', () {
    test('a quarter turn swaps width and height', () {
      final out = ImagePipeline.applyGeometry(
        _decode(_halves()),
        const GeometryParams(quarterTurns: 1),
      );
      expect(out.width, 80);
      expect(out.height, 120);
    });

    test('two quarter turns keep the dimensions', () {
      final out = ImagePipeline.applyGeometry(
        _decode(_halves()),
        const GeometryParams(quarterTurns: 2),
      );
      expect(out.width, 120);
      expect(out.height, 80);
    });

    test('a horizontal flip swaps the two halves', () {
      final source = _decode(_halves());
      expect(source.getPixel(10, 40).r, greaterThan(source.getPixel(110, 40).r));

      final out = ImagePipeline.applyGeometry(
        _decode(_halves()),
        const GeometryParams(flipH: true),
      );
      expect(out.getPixel(10, 40).r, lessThan(out.getPixel(110, 40).r));
    });

    test('a vertical flip leaves the horizontal halves in place', () {
      final out = ImagePipeline.applyGeometry(
        _decode(_halves()),
        const GeometryParams(flipV: true),
      );
      expect(out.getPixel(10, 40).r, greaterThan(out.getPixel(110, 40).r));
    });

    test('a normalised crop takes the right slice at any resolution', () {
      // The same operation against two sizes: this is what makes a crop made
      // on the 1440px preview replay correctly on a full-resolution export.
      for (final size in [120, 480]) {
        final out = ImagePipeline.applyGeometry(
          _decode(_halves(width: size, height: size)),
          const GeometryParams(left: 0, top: 0, right: 0.5, bottom: 1),
        );
        expect(out.width, size ~/ 2, reason: 'at $size px');
        expect(out.height, size);
        // The left half was the red one.
        expect(out.getPixel(out.width ~/ 2, out.height ~/ 2).r, greaterThan(150));
      }
    });

    test('an identity geometry returns the image untouched', () {
      final source = _decode(_halves());
      expect(
        identical(
          ImagePipeline.applyGeometry(source, GeometryParams.identity),
          source,
        ),
        isTrue,
      );
    });

    test('crop runs after rotation, as the crop box implies', () {
      // Turning a 120x80 frame gives 80x120; taking the top half of that is
      // 80x60. If the crop ran first it would be 60x80 instead.
      final out = ImagePipeline.applyGeometry(
        _decode(_halves()),
        const GeometryParams(quarterTurns: 1, bottom: 0.5),
      );
      expect(out.width, 80);
      expect(out.height, 60);
    });
  });

  group('effects', () {
    final source = _halves(width: 100, height: 100);

    test('vignette darkens the corners and spares the centre', () {
      final before = _decode(source);
      final after = ImagePipeline.applyEffects(
        _decode(source),
        const EffectParams(vignette: 100),
      );

      final cornerBefore = img.getLuminance(before.getPixel(2, 2));
      final cornerAfter = img.getLuminance(after.getPixel(2, 2));
      final centreBefore = img.getLuminance(before.getPixel(50, 50));
      final centreAfter = img.getLuminance(after.getPixel(50, 50));

      expect(cornerAfter, lessThan(cornerBefore));
      expect(centreAfter, closeTo(centreBefore, 6));
    });

    test('blur smooths the hard edge between the halves', () {
      final sharp = _variance(_decode(source));
      final blurred = _variance(ImagePipeline.applyEffects(
        _decode(source),
        const EffectParams(blur: 100),
        scale: 1,
      ));
      expect(blurred, lessThan(sharp));
    });

    test('grain adds variation to a flat area', () {
      final flat = _ramp(low: 128, high: 128);
      final before = _variance(_decode(flat));
      final after = _variance(ImagePipeline.applyEffects(
        _decode(flat),
        const EffectParams(grain: 100),
      ));
      expect(after, greaterThan(before + 1));
    });

    test('glow lightens the image', () {
      final before = _meanLuminance(_decode(source));
      final after = _meanLuminance(ImagePipeline.applyEffects(
        _decode(source),
        const EffectParams(glow: 100),
      ));
      expect(after, greaterThan(before));
    });

    test('effects stack rather than replace one another', () {
      final both = ImagePipeline.applyEffects(
        _decode(source),
        const EffectParams(vignette: 100, grain: 60),
      );
      final onlyVignette = ImagePipeline.applyEffects(
        _decode(source),
        const EffectParams(vignette: 100),
      );

      expect(_variance(both), greaterThan(_variance(onlyVignette)));
      expect(
        img.getLuminance(both.getPixel(2, 2)),
        lessThan(img.getLuminance(_decode(source).getPixel(2, 2))),
      );
    });

    test('no effects means no work', () {
      final source2 = _decode(source);
      expect(
        identical(
          ImagePipeline.applyEffects(source2, EffectParams.identity),
          source2,
        ),
        isTrue,
      );
    });
  });

  group('auto', () {
    test('a dark photo is lifted, and exposure wins over contrast', () {
      final suggestion = ImagePipeline.autoAdjustSync(_ramp(low: 0, high: 80));

      expect(suggestion.brightness, greaterThan(0));
      // Contrast pivots about mid-grey, so asking for both here would darken
      // the photo. Auto backs the contrast off rather than ship that.
      expect(suggestion.contrast, lessThanOrEqualTo(suggestion.brightness));
    });

    test('a well-exposed photo is left essentially alone', () {
      final suggestion = ImagePipeline.autoAdjustSync(_ramp());

      expect(suggestion.brightness, 0,
          reason: 'Auto must not "fix" a photo that was already right');
      expect(suggestion.contrast.abs(), lessThan(10));
    });

    test('a washed-out photo gets contrast back', () {
      final suggestion = ImagePipeline.autoAdjustSync(_ramp(low: 100, high: 160));
      expect(suggestion.contrast, greaterThan(20));
    });

    test('the suggestion actually lightens the photo when applied', () {
      final dark = _ramp(low: 0, high: 70);
      final suggestion = ImagePipeline.autoAdjustSync(dark);

      final before = _meanLuminance(_decode(dark));
      final after = _meanLuminance(_decode(ImagePipeline.renderSync(
        RenderRequest(bytes: dark, state: EditState(adjust: suggestion)),
      )));

      expect(after, greaterThan(before + 10));
    });

    test('suggestions stay inside the slider range', () {
      for (final bytes in [
        _ramp(low: 0, high: 5),
        _ramp(low: 250, high: 255),
        _ramp(),
      ]) {
        final s = ImagePipeline.autoAdjustSync(bytes);
        for (final v in [s.brightness, s.contrast, s.saturation]) {
          expect(v, inInclusiveRange(-100, 100));
        }
        expect(s.sharpness, 0, reason: 'Auto never touches spatial work');
      }
    });

    test('a corrupted file fails the same way a render does', () {
      expect(
        () => ImagePipeline.autoAdjustSync(Uint8List.fromList([1, 2, 3])),
        throwsA(isA<ImagePipelineFailure>()),
      );
    });
  });

  group('all three stages together', () {
    test('crop, effect and filter each show up in one render', () {
      final out = _decode(ImagePipeline.renderSync(RenderRequest(
        bytes: _halves(width: 200, height: 200),
        state: const EditState(
          geometry: GeometryParams(right: 0.5),
          effects: EffectParams(vignette: 80),
          filter: FilterParams(id: 'bw'),
        ),
        quality: 100,
      )));

      expect(out.width, 100, reason: 'geometry ran');
      final centre = out.getPixel(50, 100);
      expect(centre.r, closeTo(centre.b.toDouble(), 6), reason: 'B&W ran');
      expect(
        img.getLuminance(out.getPixel(1, 1)),
        lessThan(img.getLuminance(centre)),
        reason: 'vignette ran',
      );
    });

    test('the colour matrix folds the filter under the sliders', () {
      const state = EditState(
        adjust: AdjustParams(brightness: 40),
        filter: FilterParams(id: 'bw'),
      );
      final matrix = ImagePipeline.colorMatrixFor(state);

      // B&W first, then the brightness slider: the result is still grey.
      final out = [
        matrix[0] * 200 + matrix[1] * 60 + matrix[2] * 40 + matrix[4],
        matrix[5] * 200 + matrix[6] * 60 + matrix[7] * 40 + matrix[9],
        matrix[10] * 200 + matrix[11] * 60 + matrix[12] * 40 + matrix[14],
      ];
      expect(out[0], closeTo(out[1], 0.001));
      expect(out[1], closeTo(out[2], 0.001));
    });
  });
}
