import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/services/color_matrix.dart';
import 'package:elira/services/photo_filters.dart';
import 'package:flutter_test/flutter_test.dart';

List<double> _apply(List<double> matrix) =>
    ColorMatrix.applyToRgb(matrix, 200, 120, 60);

void main() {
  group('catalogue', () {
    test('ids are unique, because they are what gets persisted', () {
      final ids = PhotoFilters.all.map((f) => f.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('covers the looks the product asks for', () {
      expect(
        PhotoFilters.all.map((f) => f.id),
        containsAll(<String>[
          'cinematic',
          'vibrant',
          'aesthetic',
          'golden_hour',
          'bw',
          'fade',
          'warm',
          'cool',
        ]),
      );
    });

    test('only Original is neutral', () {
      expect(PhotoFilters.original.isNeutral, isTrue);
      for (final filter in PhotoFilters.all.where((f) => f.id != FilterParams.none)) {
        expect(filter.isNeutral, isFalse, reason: '${filter.id} does nothing');
      }
    });

    test('an unknown id falls back to Original instead of throwing', () {
      // A project saved by a newer build must still open.
      expect(PhotoFilters.byId('from_the_future').id, FilterParams.none);
    });
  });

  group('looks do what their names say', () {
    test('B&W removes all colour', () {
      final out = _apply(PhotoFilters.byId('bw').matrix);
      expect(out[0], closeTo(out[1], 0.001));
      expect(out[1], closeTo(out[2], 0.001));
    });

    test('Warm favours red over blue and Cool does the reverse', () {
      final warm = _apply(PhotoFilters.byId('warm').matrix);
      final cool = _apply(PhotoFilters.byId('cool').matrix);
      final base = _apply(ColorMatrix.identity);

      expect(warm[0] / warm[2], greaterThan(base[0] / base[2]));
      expect(cool[0] / cool[2], lessThan(base[0] / base[2]));
    });

    test('Vibrant increases the spread between channels', () {
      final vivid = _apply(PhotoFilters.byId('vibrant').matrix);
      final base = _apply(ColorMatrix.identity);
      expect(vivid[0] - vivid[2], greaterThan(base[0] - base[2]));
    });

    test('Fade lifts the black point', () {
      final black = ColorMatrix.applyToRgb(PhotoFilters.byId('fade').matrix, 0, 0, 0);
      expect(black[0], greaterThan(10));
    });

    test('Golden Hour warms and Cinematic cools the shadows', () {
      final golden = _apply(PhotoFilters.byId('golden_hour').matrix);
      expect(golden[0] / golden[2], greaterThan(200 / 60));

      final shadow =
          ColorMatrix.applyToRgb(PhotoFilters.byId('cinematic').matrix, 10, 10, 10);
      expect(shadow[2], greaterThan(shadow[0]));
    });
  });

  group('strength', () {
    test('zero strength is a no-op', () {
      expect(
        ColorMatrix.isIdentity(PhotoFilters.byId('bw').at(0)),
        isTrue,
      );
    });

    test('full strength is the look itself', () {
      final full = PhotoFilters.byId('warm').at(100);
      final matrix = PhotoFilters.byId('warm').matrix;
      for (var i = 0; i < matrix.length; i++) {
        expect(full[i], closeTo(matrix[i], 1e-9));
      }
    });

    test('half strength lands between the two', () {
      final base = _apply(ColorMatrix.identity);
      final half = _apply(PhotoFilters.byId('bw').at(50));
      final full = _apply(PhotoFilters.byId('bw').matrix);

      double spread(List<double> v) => v[0] - v[2];
      expect(spread(half).abs(), lessThan(spread(base).abs()));
      expect(spread(half).abs(), greaterThan(spread(full).abs()));
    });
  });

  group('matrixFor', () {
    test('Original and zero strength both resolve to identity', () {
      expect(
        ColorMatrix.isIdentity(PhotoFilters.matrixFor(FilterParams.identity)),
        isTrue,
      );
      expect(
        ColorMatrix.isIdentity(
          PhotoFilters.matrixFor(const FilterParams(id: 'bw', strength: 0)),
        ),
        isTrue,
      );
    });

    test('resolves a named look at its strength', () {
      final resolved = PhotoFilters.matrixFor(const FilterParams(id: 'cool', strength: 100));
      final matrix = PhotoFilters.byId('cool').matrix;
      for (var i = 0; i < matrix.length; i++) {
        expect(resolved[i], closeTo(matrix[i], 1e-9));
      }
    });
  });
}
