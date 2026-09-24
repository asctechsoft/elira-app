import 'package:elira/services/color_matrix.dart';
import 'package:flutter_test/flutter_test.dart';

/// Matrices are built by multiplying and blending, so componentwise
/// comparison is the honest one: bit-exact equality would be asserting
/// something about float arithmetic rather than about the matrix.
void _expectMatrix(List<double> actual, List<double> expected) {
  expect(actual.length, expected.length);
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], 1e-9), reason: 'entry $i');
  }
}

void main() {
  group('identity', () {
    test('the identity matrix is recognised as one', () {
      expect(ColorMatrix.isIdentity(ColorMatrix.identity), isTrue);
    });

    test('neutral parameters produce the identity matrix', () {
      expect(ColorMatrix.isIdentity(ColorMatrix.brightness(1)), isTrue);
      expect(ColorMatrix.isIdentity(ColorMatrix.contrast(1)), isTrue);
      expect(ColorMatrix.isIdentity(ColorMatrix.saturation(1)), isTrue);
      expect(ColorMatrix.isIdentity(ColorMatrix.channels()), isTrue);
    });

    test('any change is detected', () {
      expect(ColorMatrix.isIdentity(ColorMatrix.brightness(1.01)), isFalse);
      expect(ColorMatrix.isIdentity(ColorMatrix.channels(rLift: 1)), isFalse);
    });
  });

  group('primitives', () {
    test('brightness scales every channel', () {
      final out = ColorMatrix.applyToRgb(ColorMatrix.brightness(2), 10, 20, 30);
      expect(out, [20, 40, 60]);
    });

    test('contrast pivots around mid-grey', () {
      final m = ColorMatrix.contrast(2);
      expect(ColorMatrix.applyToRgb(m, 127.5, 127.5, 127.5)[0], closeTo(127.5, 1e-9));
      expect(ColorMatrix.applyToRgb(m, 200, 200, 200)[0], closeTo(272.5, 1e-9));
      expect(ColorMatrix.applyToRgb(m, 50, 50, 50)[0], closeTo(-27.5, 1e-9));
    });

    test('zero saturation collapses a colour onto its luma', () {
      final out = ColorMatrix.applyToRgb(ColorMatrix.saturation(0), 255, 0, 0);
      expect(out[0], closeTo(ColorMatrix.lumaR * 255, 1e-9));
      expect(out[0], closeTo(out[1], 1e-9));
      expect(out[1], closeTo(out[2], 1e-9));
    });

    test('saturation above one pushes away from grey', () {
      final base = ColorMatrix.applyToRgb(ColorMatrix.identity, 200, 100, 100);
      final vivid = ColorMatrix.applyToRgb(ColorMatrix.saturation(1.5), 200, 100, 100);
      expect(vivid[0] - vivid[1], greaterThan(base[0] - base[1]));
    });

    test('channels applies gain then lift per channel', () {
      final out = ColorMatrix.applyToRgb(
        ColorMatrix.channels(rGain: 2, bLift: 5),
        10,
        10,
        10,
      );
      expect(out, [20, 10, 15]);
    });
  });

  group('compose', () {
    test('applies the second matrix first', () {
      final m = ColorMatrix.compose(
        ColorMatrix.brightness(2),
        ColorMatrix.channels(rGain: 3),
      );
      // 10 -> (x3) 30 -> (x2) 60. The other order would give 10 -> 20 -> 60
      // for red too, so the green channel is what distinguishes them.
      expect(ColorMatrix.applyToRgb(m, 10, 10, 10), [60, 20, 20]);
    });

    test('carries offsets through the first matrix', () {
      final m = ColorMatrix.compose(
        ColorMatrix.brightness(2),
        ColorMatrix.channels(rLift: 5),
      );
      expect(ColorMatrix.applyToRgb(m, 10, 0, 0)[0], closeTo(30, 1e-9));
    });

    test('composing with identity changes nothing', () {
      final m = ColorMatrix.contrast(1.4);
      _expectMatrix(ColorMatrix.compose(m, ColorMatrix.identity), m);
      _expectMatrix(ColorMatrix.compose(ColorMatrix.identity, m), m);
    });

    test('composeAll applies the last entry first', () {
      final folded = ColorMatrix.composeAll([
        ColorMatrix.brightness(2),
        ColorMatrix.channels(rGain: 3),
      ]);
      expect(ColorMatrix.applyToRgb(folded, 10, 10, 10), [60, 20, 20]);
    });

    test('a composed matrix equals applying the two in sequence', () {
      final a = ColorMatrix.contrast(1.3);
      final b = ColorMatrix.saturation(0.4);
      final composed = ColorMatrix.applyToRgb(ColorMatrix.compose(a, b), 180, 90, 40);
      final stepwise = ColorMatrix.applyToRgb(b, 180, 90, 40);
      final expected = ColorMatrix.applyToRgb(a, stepwise[0], stepwise[1], stepwise[2]);

      for (var i = 0; i < 3; i++) {
        expect(composed[i], closeTo(expected[i], 1e-9));
      }
    });
  });

  group('lerp', () {
    final target = ColorMatrix.saturation(0);

    test('zero is the starting matrix and one is the target', () {
      _expectMatrix(
          ColorMatrix.lerp(ColorMatrix.identity, target, 0), ColorMatrix.identity);
      _expectMatrix(ColorMatrix.lerp(ColorMatrix.identity, target, 1), target);
    });

    test('half really is halfway', () {
      final half = ColorMatrix.lerp(ColorMatrix.identity, target, 0.5);
      for (var i = 0; i < 20; i++) {
        expect(half[i], closeTo((ColorMatrix.identity[i] + target[i]) / 2, 1e-9));
      }
    });

    test('out-of-range values are clamped rather than extrapolated', () {
      _expectMatrix(ColorMatrix.lerp(ColorMatrix.identity, target, 5), target);
      _expectMatrix(
          ColorMatrix.lerp(ColorMatrix.identity, target, -2), ColorMatrix.identity);
    });
  });
}
