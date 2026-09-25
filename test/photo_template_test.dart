import 'package:elira/controller/create_controller.dart';
import 'package:elira/data/templates/recent_template_store.dart';
import 'package:elira/models/data_models/edit_operation.dart';
import 'package:elira/models/data_models/photo_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

/// Replays a template's operations the way the editor would.
EditState _fold(List<EditOperation> operations) =>
    operations.fold(EditState.initial, (state, op) => state.apply(op));

void main() {
  group('catalogue', () {
    test('ids are unique, because a draft stores them', () {
      final ids = PhotoTemplates.all.map((t) => t.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('an unknown id resolves to null rather than throwing', () {
      expect(PhotoTemplates.byId('from_the_future'), isNull);
      expect(PhotoTemplates.byId('story_clean'), isNotNull);
    });

    test('every template actually does something', () {
      for (final template in PhotoTemplates.all) {
        final operations = template.toOperations(
          sourceWidth: 4000,
          sourceHeight: 3000,
        );
        expect(operations, isNotEmpty, reason: '${template.id} is a no-op');
      }
    });

    test('every category has at least one template behind it', () {
      for (final category in TemplateCategory.values) {
        expect(PhotoTemplates.byCategory(category), isNotEmpty,
            reason: '${category.label} would open empty');
      }
    });

    test('ratios are positive and labelled', () {
      for (final template in PhotoTemplates.all) {
        expect(template.aspectRatio, greaterThan(0), reason: template.id);
        expect(template.ratioLabel, isNotEmpty, reason: template.id);
      }
    });
  });

  group('centeredCrop', () {
    test('a square crop of a landscape frame takes the full height', () {
      final crop = PhotoTemplate.centeredCrop(frameAspect: 2, ratio: 1);

      expect(crop.cropHeight, closeTo(1, 0.0001));
      expect(crop.cropWidth, closeTo(0.5, 0.0001));
      expect(crop.left, closeTo(0.25, 0.0001));
    });

    test('a wide crop of a portrait frame takes the full width', () {
      final crop = PhotoTemplate.centeredCrop(frameAspect: 0.5, ratio: 16 / 9);

      expect(crop.cropWidth, closeTo(1, 0.0001));
      expect(crop.cropHeight, closeTo(0.5 / (16 / 9), 0.0001));
    });

    test('a matching ratio needs no crop at all', () {
      final crop = PhotoTemplate.centeredCrop(frameAspect: 1.5, ratio: 1.5);
      expect(crop.hasCrop, isFalse);
    });

    test('it is always centred', () {
      final crop = PhotoTemplate.centeredCrop(frameAspect: 3, ratio: 1);
      expect(crop.left, closeTo(1 - crop.right, 0.0001));
      expect(crop.top, closeTo(1 - crop.bottom, 0.0001));
    });

    test('nonsense input is the identity, not a crash', () {
      expect(PhotoTemplate.centeredCrop(frameAspect: 0, ratio: 1).isIdentity,
          isTrue);
      expect(PhotoTemplate.centeredCrop(frameAspect: 1, ratio: 0).isIdentity,
          isTrue);
    });
  });

  group('a template compiles to ordinary operations', () {
    final template = PhotoTemplates.byId('story_film')!;

    test('the crop depends on the photo, not on the template alone', () {
      final landscape =
          template.toOperations(sourceWidth: 4000, sourceHeight: 3000);
      final portrait =
          template.toOperations(sourceWidth: 3000, sourceHeight: 4000);

      final a = _fold(landscape).geometry;
      final b = _fold(portrait).geometry;

      expect(a.cropWidth, isNot(closeTo(b.cropWidth, 0.01)),
          reason: '9:16 is a different rectangle on each');
      // Both still end up at the template's ratio.
      for (final (crop, w, h) in [(a, 4000, 3000), (b, 3000, 4000)]) {
        final ratio = (w * crop.cropWidth) / (h * crop.cropHeight);
        expect(ratio, closeTo(template.aspectRatio, 0.01));
      }
    });

    test('the look lands in the folded state', () {
      final state = _fold(
        template.toOperations(sourceWidth: 2000, sourceHeight: 2000),
      );

      expect(state.filter.id, 'fade');
      expect(state.filter.strength, 80);
      expect(state.effects.grain, 35);
      expect(state.effects.vignette, 25);
    });

    test('adjust-only templates produce no filter operation', () {
      final clean = PhotoTemplates.byId('product_clean')!;
      final state = _fold(
        clean.toOperations(sourceWidth: 1000, sourceHeight: 1000),
      );

      expect(state.filter.isIdentity, isTrue);
      expect(state.adjust.sharpness, 35);
      expect(state.adjust.brightness, 18);
    });

    test('a photo with no dimensions still gets the look, minus the crop', () {
      final operations = template.toOperations(sourceWidth: 0, sourceHeight: 0);

      expect(operations.any((o) => o.type == EditOperationType.crop), isFalse);
      expect(_fold(operations).filter.id, 'fade');
    });

    test('every operation survives the round trip a draft stores', () {
      final adjustments =
          template.toAdjustments(sourceWidth: 4000, sourceHeight: 3000);

      expect(adjustments['templateId'], 'story_film');
      final restored = (adjustments['operations'] as List)
          .map((m) =>
              EditOperation.fromMap((m as Map).map((k, v) => MapEntry('$k', v))))
          .toList();

      expect(restored.length,
          template.toOperations(sourceWidth: 4000, sourceHeight: 3000).length);
      expect(_fold(restored).filter.id, 'fade');
      expect(_fold(restored).geometry.hasCrop, isTrue);
    });

    test('applying one is undoable step by step', () {
      // Each operation is a separate entry, so a user who likes the crop but
      // not the grain can undo just the grain.
      final operations =
          template.toOperations(sourceWidth: 4000, sourceHeight: 3000);

      expect(operations.length, greaterThan(1));
      expect(operations.map((o) => o.type),
          containsAll([EditOperationType.crop, EditOperationType.filter]));
    });
  });

  group('CreateController', () {
    setUp(() => Get.testMode = true);
    tearDown(Get.reset);

    test('shows every template until a category is chosen', () {
      final ctrl = CreateController(recents: InMemoryRecentTemplateStore());

      expect(ctrl.templates.length, PhotoTemplates.all.length);

      ctrl.selectCategory(TemplateCategory.portrait);
      expect(ctrl.templates, isNotEmpty);
      expect(ctrl.templates.every((t) => t.category == TemplateCategory.portrait),
          isTrue);

      ctrl.selectCategory(null);
      expect(ctrl.templates.length, PhotoTemplates.all.length);
    });

    test('recents resolve against the catalogue', () async {
      final ctrl = CreateController(
        recents: InMemoryRecentTemplateStore(['post_mono', 'story_clean']),
      );
      await ctrl.loadRecents();

      expect(ctrl.recentTemplates.map((t) => t.id), ['post_mono', 'story_clean']);
      expect(ctrl.hasRecents, isTrue);
    });

    test('an id left over from an older build is dropped, not shown empty',
        () async {
      final ctrl = CreateController(
        recents: InMemoryRecentTemplateStore(['deleted_template', 'post_mono']),
      );
      await ctrl.loadRecents();

      expect(ctrl.recentTemplates.map((t) => t.id), ['post_mono']);
    });

    test('a fresh install has no recents', () async {
      final ctrl = CreateController(recents: InMemoryRecentTemplateStore());
      await ctrl.loadRecents();

      expect(ctrl.hasRecents, isFalse);
    });

    test('the quick-create tiles that cannot work say why', () {
      for (final entry in CreateController.unavailable.entries) {
        expect(entry.value, isNotEmpty, reason: entry.key);
        expect(PhotoTemplates.byId(entry.key), isNull,
            reason: '${entry.key} is listed as unavailable but exists');
      }
    });

    test('the tiles that can work map to real templates', () {
      for (final id in ['story_clean', 'post_vivid']) {
        expect(PhotoTemplates.byId(id), isNotNull);
        expect(CreateController.unavailable.containsKey(id), isFalse);
      }
    });
  });

  group('recent store', () {
    test('most recent first, no duplicates', () async {
      final store = InMemoryRecentTemplateStore();

      await store.remember('a');
      await store.remember('b');
      await store.remember('a');

      expect(await store.load(), ['a', 'b']);
    });

    test('caps the list', () async {
      final store = InMemoryRecentTemplateStore();
      for (var i = 0; i < 20; i++) {
        await store.remember('t$i');
      }

      expect((await store.load()).length, PrefsRecentTemplateStore.maxEntries);
      expect((await store.load()).first, 't19');
    });
  });
}
