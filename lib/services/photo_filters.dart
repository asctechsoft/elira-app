import '../models/data_models/edit_operation.dart';
import 'color_matrix.dart';

/// One look. The matrix is the whole implementation: because a filter is a
/// colour matrix and nothing else, selecting one costs no pixel work — the
/// canvas folds it into the same GPU filter it already applies for the Adjust
/// sliders.
class PhotoFilter {
  const PhotoFilter({
    required this.id,
    required this.name,
    required this.matrix,
  });

  final String id;
  final String name;
  final List<double> matrix;

  bool get isNeutral => ColorMatrix.isIdentity(matrix);

  /// The matrix for this look at [strength] percent.
  List<double> at(double strength) =>
      ColorMatrix.lerp(ColorMatrix.identity, matrix, strength / 100);
}

/// The filter catalogue. Ids are persisted in the edit stack, so they are API:
/// rename a [name] freely, never an [id].
class PhotoFilters {
  const PhotoFilters._();

  static const original = PhotoFilter(
    id: FilterParams.none,
    name: 'Original',
    matrix: ColorMatrix.identity,
  );

  static final List<PhotoFilter> all = [
    original,
    PhotoFilter(
      id: 'cinematic',
      name: 'Cinematic',
      // Teal shadows against warm skin, with the lifted blacks of a film print.
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(
          rGain: 1.06,
          bGain: 1.10,
          rLift: 2,
          gLift: 4,
          bLift: 12,
        ),
        ColorMatrix.contrast(1.14),
        ColorMatrix.saturation(0.88),
      ]),
    ),
    PhotoFilter(
      id: 'vibrant',
      name: 'Vibrant',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.contrast(1.12),
        ColorMatrix.saturation(1.45),
      ]),
    ),
    PhotoFilter(
      id: 'aesthetic',
      name: 'Aesthetic',
      // Soft, low-contrast pastel with a faint magenta lift.
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(rGain: 1.04, bGain: 1.05, rLift: 10, gLift: 8, bLift: 12),
        ColorMatrix.contrast(0.88),
        ColorMatrix.saturation(0.92),
      ]),
    ),
    PhotoFilter(
      id: 'golden_hour',
      name: 'Golden Hour',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(rGain: 1.16, gGain: 1.02, bGain: 0.84, rLift: 8, gLift: 2),
        ColorMatrix.contrast(1.06),
        ColorMatrix.saturation(1.12),
      ]),
    ),
    PhotoFilter(
      id: 'bw',
      name: 'B&W',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.contrast(1.18),
        ColorMatrix.saturation(0),
      ]),
    ),
    PhotoFilter(
      id: 'fade',
      name: 'Fade',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(rLift: 24, gLift: 22, bLift: 20),
        ColorMatrix.contrast(0.76),
        ColorMatrix.saturation(0.84),
      ]),
    ),
    PhotoFilter(
      id: 'warm',
      name: 'Warm',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(rGain: 1.13, gGain: 1.02, bGain: 0.89),
        ColorMatrix.saturation(1.06),
      ]),
    ),
    PhotoFilter(
      id: 'cool',
      name: 'Cool',
      matrix: ColorMatrix.composeAll([
        ColorMatrix.channels(rGain: 0.89, gGain: 1.01, bGain: 1.15),
        ColorMatrix.saturation(1.06),
      ]),
    ),
  ];

  /// Unknown ids resolve to [original] rather than throwing: a project saved
  /// by a newer build must still open, just without the look it cannot name.
  static PhotoFilter byId(String id) =>
      all.firstWhere((f) => f.id == id, orElse: () => original);

  static List<double> matrixFor(FilterParams params) =>
      params.isIdentity ? ColorMatrix.identity : byId(params.id).at(params.strength);
}
