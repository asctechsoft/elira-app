import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/editor_controller.dart';
import 'package:elira/data/projects/in_memory_project_repository.dart';
import 'package:elira/models/data_models/photo_template.dart';
import 'package:elira/services/project_draft_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

Uint8List _photo({int width = 400, int height = 300}) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(130, 120, 110));
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

/// Picking a photo from a template has to arrive in the editor as real,
/// undoable edits. This walks the whole path: draft creation writes the
/// template into the project, and the editor restores it on open.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  late File source;
  late InMemoryProjectRepository repository;
  late ProjectDraftService drafts;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('elira_template_flow');
    source = File('${tmp.path}${Platform.pathSeparator}camera.jpg');
    await source.writeAsBytes(_photo());
    repository = InMemoryProjectRepository();
    drafts = ProjectDraftService(rootOverride: tmp, repository: repository);
  });

  tearDown(() async {
    Get.reset();
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<EditorController> openEditorFor(PhotoTemplate? template) async {
    final project = await drafts.createFromFile(source, template: template);
    final ctrl = EditorController(
      renderDelay: Duration.zero,
      saveDelay: Duration.zero,
      projects: repository,
    );
    ctrl.setProject(project);
    await ctrl.load();
    return ctrl;
  }

  test('a draft made without a template starts clean', () async {
    final ctrl = await openEditorFor(null);

    expect(ctrl.history, isEmpty);
    expect(ctrl.canUndo.value, isFalse);
    expect(ctrl.filterId.value, 'original');
  });

  test('a template arrives in the editor as applied edits', () async {
    final template = PhotoTemplates.byId('story_film')!;
    final ctrl = await openEditorFor(template);

    expect(ctrl.filterId.value, 'fade');
    expect(ctrl.filterStrength.value, 80);
    expect(ctrl.grain.value, 35);
    expect(ctrl.vignette.value, 25);
    expect(ctrl.geometry.value.hasCrop, isTrue);
  });

  test('the crop matches the template ratio for this photo', () async {
    final template = PhotoTemplates.byId('post_vivid')!;
    final ctrl = await openEditorFor(template);

    final project = ctrl.project.value!;
    final crop = ctrl.geometry.value;
    final ratio = (project.width * crop.cropWidth) /
        (project.height * crop.cropHeight);

    expect(ratio, closeTo(1, 0.02), reason: 'a 1:1 template must yield a square');
  });

  test('every step of a template is undoable', () async {
    final template = PhotoTemplates.byId('story_film')!;
    final ctrl = await openEditorFor(template);

    expect(ctrl.canUndo.value, isTrue);
    final steps = ctrl.history.length;
    expect(steps, greaterThan(1));

    // Undo the last step only: the rest of the template stays.
    await ctrl.undo();
    expect(ctrl.canUndo.value, isTrue);
    expect(ctrl.geometry.value.hasCrop, isTrue);

    for (var i = 1; i < steps; i++) {
      await ctrl.undo();
    }
    expect(ctrl.canUndo.value, isFalse);
    expect(ctrl.geometry.value.hasCrop, isFalse,
        reason: 'undoing the whole template returns to the untouched photo');
    expect(ctrl.filterId.value, 'original');
  });

  test('the template is persisted, so reopening keeps it', () async {
    final template = PhotoTemplates.byId('portrait_golden')!;
    await openEditorFor(template);

    final saved = await repository.recent();
    expect(saved, hasLength(1));
    expect(saved.first.adjustments['templateId'], 'portrait_golden');

    final reopened = EditorController(
      renderDelay: Duration.zero,
      saveDelay: Duration.zero,
      projects: repository,
    );
    reopened.setProject(saved.first);
    await reopened.load();

    expect(reopened.filterId.value, 'golden_hour');
    expect(reopened.glow.value, 20);
  });

  test('the original photo is untouched by the template', () async {
    final before = await source.readAsBytes();
    await openEditorFor(PhotoTemplates.byId('cinematic_wide')!);

    expect(await source.readAsBytes(), before);
  });

  test('a draft is saved to the repository even with no template', () async {
    await openEditorFor(null);
    expect(await repository.count(), 1);
  });
}
