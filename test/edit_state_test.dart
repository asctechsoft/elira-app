import 'package:elira/models/data_models/edit_operation.dart';
import 'package:flutter_test/flutter_test.dart';

EditOperation _op(EditOperationType type, Map<String, dynamic> params) =>
    EditOperation(type: type, label: type.name, params: params);

void main() {
  group('slices are independent', () {
    const start = EditState(
      adjust: AdjustParams(brightness: 40),
      filter: FilterParams(id: 'warm', strength: 80),
      effects: EffectParams(vignette: 30),
      geometry: GeometryParams(quarterTurns: 1, left: 0.1, right: 0.9),
    );

    test('a filter operation leaves the crop and the sliders alone', () {
      final next = start.apply(
        _op(EditOperationType.filter, const FilterParams(id: 'bw').toMap()),
      );

      expect(next.filter.id, 'bw');
      expect(next.adjust, start.adjust, reason: 'choosing a look is not a reset');
      expect(next.geometry, start.geometry);
      expect(next.effects, start.effects);
    });

    test('a crop operation leaves the colour work alone', () {
      final next = start.apply(
        _op(EditOperationType.crop,
            const GeometryParams(quarterTurns: 2).toMap()),
      );

      expect(next.geometry.quarterTurns, 2);
      expect(next.filter, start.filter);
      expect(next.adjust, start.adjust);
    });

    test('an adjust operation leaves the filter alone', () {
      final next = start.apply(
        _op(EditOperationType.adjust, const AdjustParams(contrast: 10).toMap()),
      );

      expect(next.adjust.contrast, 10);
      expect(next.adjust.brightness, 0, reason: 'adjust is last-wins as a set');
      expect(next.filter, start.filter);
    });

    test('an effects operation leaves everything else alone', () {
      final next = start.apply(
        _op(EditOperationType.effects, const EffectParams(grain: 50).toMap()),
      );

      expect(next.effects.grain, 50);
      expect(next.effects.vignette, 0);
      expect(next.geometry, start.geometry);
      expect(next.filter, start.filter);
    });
  });

  group('spatialKey', () {
    test('colour work never invalidates the cached CPU render', () {
      const base = EditState();
      final tinted = base.copyWith(
        adjust: const AdjustParams(brightness: 80, contrast: -40, saturation: 60),
        filter: const FilterParams(id: 'cinematic', strength: 42),
      );

      expect(tinted.spatialKey, base.spatialKey,
          reason: 'sliders and filters are GPU-only; re-rendering would be waste');
    });

    test('each spatial parameter does invalidate it', () {
      const base = EditState();
      final variants = [
        base.copyWith(adjust: const AdjustParams(sharpness: 20)),
        base.copyWith(effects: const EffectParams(vignette: 20)),
        base.copyWith(effects: const EffectParams(grain: 20)),
        base.copyWith(effects: const EffectParams(blur: 20)),
        base.copyWith(effects: const EffectParams(glow: 20)),
        base.copyWith(geometry: const GeometryParams(quarterTurns: 1)),
        base.copyWith(geometry: const GeometryParams(flipH: true)),
        base.copyWith(geometry: const GeometryParams(flipV: true)),
        base.copyWith(geometry: const GeometryParams(right: 0.5)),
      ];

      for (final variant in variants) {
        expect(variant.spatialKey, isNot(base.spatialKey),
            reason: '$variant must trigger a re-render');
      }
      expect(variants.map((v) => v.spatialKey).toSet().length, variants.length,
          reason: 'two different spatial states must not share a cache entry');
    });

    test('isSpatialIdentity is true only when the CPU has nothing to do', () {
      expect(EditState.initial.isSpatialIdentity, isTrue);
      expect(
        const EditState(adjust: AdjustParams(brightness: 90)).isSpatialIdentity,
        isTrue,
      );
      expect(
        const EditState(adjust: AdjustParams(sharpness: 1)).isSpatialIdentity,
        isFalse,
      );
      expect(
        const EditState(effects: EffectParams(grain: 1)).isSpatialIdentity,
        isFalse,
      );
    });
  });

  group('geometry transforms', () {
    test('four rotations return to the start', () {
      const start = GeometryParams(left: 0.1, top: 0.2, right: 0.8, bottom: 0.7);
      var g = start;
      for (var i = 0; i < 4; i++) {
        g = g.rotatedCw();
      }

      expect(g.quarterTurns, 0);
      expect(g.left, closeTo(start.left, 1e-9));
      expect(g.top, closeTo(start.top, 1e-9));
      expect(g.right, closeTo(start.right, 1e-9));
      expect(g.bottom, closeTo(start.bottom, 1e-9));
    });

    test('rotating carries the crop box instead of discarding it', () {
      const start = GeometryParams(left: 0, top: 0, right: 0.5, bottom: 1);
      final turned = start.rotatedCw();

      expect(turned.hasCrop, isTrue, reason: 'the crop must survive a rotate');
      // A left-hand half becomes a top half once the frame turns clockwise.
      expect(turned.top, closeTo(0, 1e-9));
      expect(turned.bottom, closeTo(0.5, 1e-9));
      expect(turned.left, closeTo(0, 1e-9));
      expect(turned.right, closeTo(1, 1e-9));
    });

    test('flipping twice is a no-op and mirrors the box once', () {
      const start = GeometryParams(left: 0.1, right: 0.6);
      final once = start.flippedH();

      expect(once.flipH, isTrue);
      expect(once.left, closeTo(0.4, 1e-9));
      expect(once.right, closeTo(0.9, 1e-9));

      final twice = once.flippedH();
      expect(twice.flipH, isFalse);
      expect(twice.left, closeTo(start.left, 1e-9));
      expect(twice.right, closeTo(start.right, 1e-9));
    });

    test('vertical flip mirrors only the vertical edges', () {
      const start = GeometryParams(top: 0.2, bottom: 0.9, left: 0.1, right: 0.6);
      final flipped = start.flippedV();

      expect(flipped.top, closeTo(0.1, 1e-9));
      expect(flipped.bottom, closeTo(0.8, 1e-9));
      expect(flipped.left, closeTo(start.left, 1e-9));
    });

    test('swapsAxes is true for the quarter turns that transpose the frame', () {
      expect(const GeometryParams(quarterTurns: 0).swapsAxes, isFalse);
      expect(const GeometryParams(quarterTurns: 1).swapsAxes, isTrue);
      expect(const GeometryParams(quarterTurns: 2).swapsAxes, isFalse);
      expect(const GeometryParams(quarterTurns: 3).swapsAxes, isTrue);
    });

    test('normalised keeps the box inside the frame and non-degenerate', () {
      const bad = GeometryParams(left: -0.5, top: 0.9, right: 0.2, bottom: 0.91);
      final fixed = bad.normalised();

      expect(fixed.left, greaterThanOrEqualTo(0));
      expect(fixed.right, greaterThan(fixed.left));
      expect(fixed.bottom, greaterThan(fixed.top));
      expect(fixed.right, lessThanOrEqualTo(1));
    });

    test('withoutCrop keeps the rotation', () {
      const g = GeometryParams(quarterTurns: 3, flipH: true, left: 0.3);
      final full = g.withoutCrop();

      expect(full.hasCrop, isFalse);
      expect(full.quarterTurns, 3);
      expect(full.flipH, isTrue);
    });
  });

  group('serialisation', () {
    test('a full state round-trips', () {
      const state = EditState(
        adjust: AdjustParams(brightness: 12, contrast: -4, sharpness: 30),
        filter: FilterParams(id: 'fade', strength: 65),
        effects: EffectParams(vignette: 20, grain: 10, blur: 5, glow: 40),
        geometry: GeometryParams(
            quarterTurns: 2, flipV: true, left: 0.1, right: 0.85),
      );

      expect(EditState.fromMap(state.toMap()), state);
    });

    test('a document missing every slice decodes to the initial state', () {
      expect(EditState.fromMap(const {}), EditState.initial);
    });

    test('junk in a slice does not crash the editor', () {
      final decoded = EditState.fromMap(const {
        'adjust': {'brightness': 'lots'},
        'filter': {'strength': null},
        'geometry': {'quarterTurns': 9},
      });

      expect(decoded.adjust.brightness, 0);
      expect(decoded.filter.strength, 0);
      expect(decoded.geometry.quarterTurns, 1, reason: '9 % 4');
    });

    test('an operation of an unknown type decodes as an adjust', () {
      final op = EditOperation.fromMap(const {'type': 'teleport', 'label': 'X'});
      expect(op.type, EditOperationType.adjust);
    });
  });
}
