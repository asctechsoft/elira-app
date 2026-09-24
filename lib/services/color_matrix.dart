import 'dart:math' as math;

/// 4x5 row-major colour matrices, in exactly the layout `ColorFilter.matrix`
/// expects: offsets live in the fifth column on a 0..255 scale.
///
/// Every purely-colour edit in the app — the four Adjust sliders and every
/// filter preset — reduces to one of these. Because two matrices compose into
/// a third, the canvas can apply "filter then adjust" as a *single* GPU filter
/// per frame, with no pixel work on the CPU at all.
class ColorMatrix {
  const ColorMatrix._();

  /// Rec. 709 luma weights, used for the saturation axis.
  static const double lumaR = 0.2126, lumaG = 0.7152, lumaB = 0.0722;

  static const List<double> identity = [
    1, 0, 0, 0, 0, //
    0, 1, 0, 0, 0, //
    0, 0, 1, 0, 0, //
    0, 0, 0, 1, 0, //
  ];

  /// Multiplies every channel by [value]; 1.0 leaves the image alone.
  static List<double> brightness(double value) => [
        value, 0, 0, 0, 0, //
        0, value, 0, 0, 0, //
        0, 0, value, 0, 0, //
        0, 0, 0, 1, 0, //
      ];

  /// Expands or compresses around mid-grey.
  static List<double> contrast(double value) {
    final offset = 127.5 * (1 - value);
    return [
      value, 0, 0, 0, offset, //
      0, value, 0, 0, offset, //
      0, 0, value, 0, offset, //
      0, 0, 0, 1, 0, //
    ];
  }

  /// 0 is fully grey, 1 unchanged, above 1 more vivid.
  static List<double> saturation(double value) {
    List<double> row(int i) => [
          (1 - value) * lumaR + (i == 0 ? value : 0),
          (1 - value) * lumaG + (i == 1 ? value : 0),
          (1 - value) * lumaB + (i == 2 ? value : 0),
          0,
          0,
        ];
    return [...row(0), ...row(1), ...row(2), 0, 0, 0, 1, 0];
  }

  /// Per-channel gain and lift — the building block for a colour cast. Lifts
  /// are in 0..255, so a positive lift on all three raises the black point,
  /// which is what makes a "faded" look.
  static List<double> channels({
    double rGain = 1,
    double gGain = 1,
    double bGain = 1,
    double rLift = 0,
    double gLift = 0,
    double bLift = 0,
  }) =>
      [
        rGain, 0, 0, 0, rLift, //
        0, gGain, 0, 0, gLift, //
        0, 0, bGain, 0, bLift, //
        0, 0, 0, 1, 0, //
      ];

  /// Returns the matrix equivalent to applying [second] and then [first].
  /// Order matters: `compose(adjust, filter)` filters first, so the user's
  /// sliders correct the look rather than the look overriding the sliders.
  static List<double> compose(List<double> first, List<double> second) {
    final out = List<double>.filled(20, 0);
    for (var i = 0; i < 4; i++) {
      for (var j = 0; j < 4; j++) {
        var sum = 0.0;
        for (var k = 0; k < 4; k++) {
          sum += first[i * 5 + k] * second[k * 5 + j];
        }
        out[i * 5 + j] = sum;
      }
      var offset = first[i * 5 + 4];
      for (var k = 0; k < 4; k++) {
        offset += first[i * 5 + k] * second[k * 5 + 4];
      }
      out[i * 5 + 4] = offset;
    }
    return out;
  }

  static List<double> composeAll(List<List<double>> matrices) =>
      matrices.fold(identity, compose);

  /// Blends toward [target] by [t] in 0..1. This is what a filter's strength
  /// slider does, and it is linear in matrix space so 50% really is halfway.
  static List<double> lerp(List<double> from, List<double> target, double t) {
    final k = t.clamp(0.0, 1.0);
    return List<double>.generate(20, (i) => from[i] + (target[i] - from[i]) * k);
  }

  static bool isIdentity(List<double> m) {
    for (var i = 0; i < 20; i++) {
      final expected = (i % 6 == 0 && i < 19) ? 1.0 : 0.0;
      if ((m[i] - expected).abs() > 1e-9) return false;
    }
    return true;
  }

  /// Applies the matrix to one RGB triple in 0..255. Used by the CPU path so
  /// an export is pixel-for-pixel what the GPU showed in the canvas.
  static List<double> applyToRgb(List<double> m, double r, double g, double b) =>
      [
        m[0] * r + m[1] * g + m[2] * b + m[4],
        m[5] * r + m[6] * g + m[7] * b + m[9],
        m[10] * r + m[11] * g + m[12] * b + m[14],
      ];

  /// A rough "how far from neutral is this look" measure, used only to order
  /// or describe presets in tests.
  static double distanceFromIdentity(List<double> m) {
    var sum = 0.0;
    for (var i = 0; i < 20; i++) {
      final expected = (i % 6 == 0 && i < 19) ? 1.0 : 0.0;
      sum += math.pow(m[i] - expected, 2).toDouble();
    }
    return math.sqrt(sum);
  }
}
