import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/controller/home_controller.dart';
import 'package:elira/data/projects/in_memory_project_repository.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

EditProject _project(
  String id, {
  String name = 'Trip',
  DateTime? updatedAt,
  String? thumbnailPath = '/tmp/thumb.jpg',
}) {
  final now = updatedAt ?? DateTime.now();
  return EditProject(
    id: id,
    name: name,
    originalPath: '/tmp/$id.jpg',
    thumbnailPath: thumbnailPath,
    width: 100,
    height: 80,
    createdAt: now,
    updatedAt: now,
  );
}

/// Fails every read, to exercise the "database is unavailable" path.
class _BrokenRepository extends InMemoryProjectRepository {
  @override
  Future<List<EditProject>> recent({int limit = 20}) async =>
      throw Exception('disk is on fire');
}

Uint8List _jpeg() {
  final image = img.Image(width: 40, height: 40);
  img.fill(image, color: img.ColorRgb8(110, 110, 110));
  return Uint8List.fromList(img.encodeJpg(image, quality: 90));
}

void main() {
  setUp(() => Get.testMode = true);
  tearDown(Get.reset);

  group('recent projects', () {
    test('loads them newest first on init', () async {
      final base = DateTime(2026, 1, 1);
      final repository = InMemoryProjectRepository([
        _project('old', updatedAt: base),
        _project('new', updatedAt: base.add(const Duration(days: 1))),
      ]);

      final ctrl = HomeController(projects: repository);
      await ctrl.loadProjects();

      expect(ctrl.recentProjects.map((p) => p.id), ['new', 'old']);
      expect(ctrl.hasProjects, isTrue);
      expect(ctrl.isLoadingProjects.value, isFalse);
    });

    test('a fresh install has no projects and does not pretend otherwise',
        () async {
      final ctrl = HomeController(projects: InMemoryProjectRepository());
      await ctrl.loadProjects();

      expect(ctrl.recentProjects, isEmpty);
      expect(ctrl.hasProjects, isFalse);
      // The old screen hardcoded "Santorini Trip" and "My Puppy" here.
      expect(ctrl.latestThumbnail, isNull);
    });

    test('caps the list at the Home limit', () async {
      final repository = InMemoryProjectRepository([
        for (var i = 0; i < 25; i++)
          _project('p$i', updatedAt: DateTime(2026, 1, 1).add(Duration(days: i))),
      ]);

      final ctrl = HomeController(projects: repository);
      await ctrl.loadProjects();

      expect(ctrl.recentProjects.length, HomeController.recentLimit);
    });

    test('a failing database leaves Home usable', () async {
      final ctrl = HomeController(projects: _BrokenRepository());
      await ctrl.loadProjects();

      expect(ctrl.projectsFailed.value, isTrue);
      expect(ctrl.recentProjects, isEmpty);
      expect(ctrl.isLoadingProjects.value, isFalse);
    });

    test('deleting removes the card and the row', () async {
      final repository = InMemoryProjectRepository([_project('p1'), _project('p2')]);
      final ctrl = HomeController(projects: repository);
      await ctrl.loadProjects();

      await ctrl.deleteProject('p1');

      expect(ctrl.recentProjects.map((p) => p.id), ['p2']);
      expect(await repository.byId('p1'), isNull);
    });

    test('latestThumbnail skips projects that have none', () async {
      final base = DateTime(2026, 1, 1);
      final repository = InMemoryProjectRepository([
        _project('withThumb',
            updatedAt: base, thumbnailPath: '/tmp/a.jpg'),
        _project('noThumb',
            updatedAt: base.add(const Duration(days: 1)), thumbnailPath: null),
      ]);

      final ctrl = HomeController(projects: repository);
      await ctrl.loadProjects();

      expect(ctrl.latestThumbnail, '/tmp/a.jpg');
    });
  });

  group('presets', () {
    test('are the editor\'s real filters, not invented names', () {
      final ctrl = HomeController(projects: InMemoryProjectRepository());

      expect(ctrl.presets, isNotEmpty);
      for (final preset in ctrl.presets) {
        expect(preset.isNeutral, isFalse,
            reason: 'Original is not worth a card on Home');
      }
      expect(ctrl.presets.map((f) => f.id), contains('cinematic'));
    });
  });

  group('the editor writes back to the repository', () {
    late Directory tmp;
    late File source;
    late InMemoryProjectRepository repository;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('elira_home_test');
      source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
      await source.writeAsBytes(_jpeg());
      repository = InMemoryProjectRepository();
    });

    tearDown(() async {
      try {
        if (await tmp.exists()) await tmp.delete(recursive: true);
      } on FileSystemException catch (_) {}
    });

    EditProject seeded() {
      final now = DateTime.now();
      return EditProject(
        id: 'p1',
        name: 'Trip',
        originalPath: source.path,
        width: 40,
        height: 40,
        createdAt: now,
        updatedAt: now,
      );
    }

    Future<EditorController> open(EditProject project) async {
      await repository.save(project);
      final ctrl = EditorController(
        renderDelay: Duration.zero,
        saveDelay: Duration.zero,
        projects: repository,
      );
      ctrl.setProject(project);
      await ctrl.load();
      return ctrl;
    }

    test('an edit is written back so Home can reopen it', () async {
      final ctrl = await open(seeded());

      ctrl.setAdjust(brightness: 45);
      await ctrl.commitAdjust('Brightness');
      await ctrl.saveNow();

      final saved = await repository.byId('p1');
      final operations = saved!.adjustments['operations'] as List;
      expect(operations, hasLength(1));
      expect(operations.first['label'], 'Brightness');
    });

    test('reopening a saved project restores the edits and the history',
        () async {
      final ctrl = await open(seeded());
      ctrl.setAdjust(brightness: 45);
      await ctrl.commitAdjust('Brightness');
      ctrl.setAdjust(contrast: 20);
      await ctrl.commitAdjust('Contrast');
      await ctrl.saveNow();

      final reopened = EditorController(
        renderDelay: Duration.zero,
        saveDelay: Duration.zero,
        projects: repository,
      );
      reopened.setProject((await repository.byId('p1'))!);
      await reopened.load();

      expect(reopened.brightness.value, 45);
      expect(reopened.contrast.value, 20);
      expect(reopened.history.map((o) => o.label), ['Brightness', 'Contrast']);
      expect(reopened.canUndo.value, isTrue,
          reason: 'the undo history survives the app being closed');
    });

    test('undo is written back too, not just the latest edit', () async {
      final ctrl = await open(seeded());
      ctrl.setAdjust(brightness: 45);
      await ctrl.commitAdjust('Brightness');
      ctrl.setAdjust(contrast: 20);
      await ctrl.commitAdjust('Contrast');
      await ctrl.undo();
      await ctrl.saveNow();

      final saved = await repository.byId('p1');
      expect((saved!.adjustments['operations'] as List), hasLength(1),
          reason: 'only the applied operations are saved');
    });

    test('a project saved by a newer build still opens', () async {
      final broken = seeded().copyWith(
        adjustments: const {'v': 99, 'operations': 'not a list'},
      );
      await repository.save(broken);

      final ctrl = EditorController(
        renderDelay: Duration.zero,
        projects: repository,
      );
      ctrl.setProject(broken);
      await ctrl.load();

      expect(ctrl.history, isEmpty);
      expect(ctrl.errorMessage.value, isNull);
    });

    test('a project with no saved edits opens clean', () async {
      final ctrl = await open(seeded());

      expect(ctrl.history, isEmpty);
      expect(ctrl.canUndo.value, isFalse);
      expect(ctrl.brightness.value, 0);
    });
  });
}
