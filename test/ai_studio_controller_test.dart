import 'dart:io';
import 'dart:typed_data';

import 'package:elira/controller/ai_studio_controller.dart';
import 'package:elira/controller/auth_controller.dart';
import 'package:elira/controller/editor_controller.dart';
import 'package:elira/data/ai/ai_failure.dart';
import 'package:elira/data/ai/ai_job.dart';
import 'package:elira/data/ai/fake_ai_service.dart';
import 'package:elira/data/auth/fake_auth_service.dart';
import 'package:elira/data/user/in_memory_user_repository.dart';
import 'package:elira/models/data_models/ai_tool.dart';
import 'package:elira/models/data_models/app_user.dart';
import 'package:elira/models/data_models/edit_project.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;

Uint8List _jpeg({int shade = 90}) {
  final image = img.Image(width: 50, height: 50);
  img.fill(image, color: img.ColorRgb8(shade, shade, shade));
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

void main() {
  late Directory tmp;
  late File source;
  late FakeAuthService auth;
  late InMemoryUserRepository users;
  late AuthController authController;

  setUp(() async {
    Get.testMode = true;
    tmp = await Directory.systemTemp.createTemp('elira_ai_ctrl');
    source = File('${tmp.path}${Platform.pathSeparator}original.jpg');
    await source.writeAsBytes(_jpeg());

    auth = FakeAuthService();
    users = InMemoryUserRepository();
    authController = AuthController(auth, users);
  });

  tearDown(() async {
    authController.onClose();
    auth.dispose();
    Get.reset();
    try {
      if (await tmp.exists()) await tmp.delete(recursive: true);
    } on FileSystemException catch (_) {}
  });

  Future<void> signIn() async {
    await authController.restoreSession();
    await authController.signUpWithEmail(
      name: 'Linh',
      email: 'linh@example.com',
      password: 'secret123',
    );
  }

  Future<void> signInAsGuest() async {
    await authController.restoreSession();
    await authController.continueAsGuest();
  }

  AiStudioController build({FakeAiService? service}) => AiStudioController(
        service: service ?? FakeAiService(),
        auth: authController,
      );

  group('credits', () {
    test('come from the profile, not from a hardcoded number', () async {
      await signIn();
      final ai = build();

      expect(ai.credits, UserCredits.signupGrant);
      expect(ai.credits, isNot(120), reason: 'the old placeholder is gone');
    });

    test('are zero before anyone is signed in', () {
      expect(build().credits, 0);
    });

    test('affordability is judged against the real balance', () async {
      await signIn();
      final ai = build();

      expect(ai.canAfford(AiTools.enhance), isTrue);
      expect(ai.canAfford(AiTools.headshot), isTrue);
      expect(
        ai.canAfford(const AiTool(
          id: 'x',
          name: 'X',
          tagline: '',
          credits: UserCredits.signupGrant + 1,
        )),
        isFalse,
      );
    });
  });

  group('gating', () {
    test('an unconfigured build blocks before anything is sent', () async {
      await signIn();
      final service = FakeAiService(configured: false);
      final ai = AiStudioController(service: service, auth: authController);

      expect(ai.blockerFor(AiTools.enhance), AiFailureCode.notConfigured);
      await ai.run(AiTools.enhance, imagePath: source.path);

      expect(service.requests, isEmpty, reason: 'nothing should reach the service');
      expect(ai.lastFailure.value?.code, AiFailureCode.notConfigured);
    });

    // FeatureFlags.creditsEnabled is off for the current demo/dev phase, so
    // blockerFor skips the account and balance checks below even though
    // requiresAccount/canAfford themselves still report the real state.
    test('a guest can run tools while the credit gate is disabled', () async {
      await signInAsGuest();
      final service = FakeAiService();
      final ai = AiStudioController(service: service, auth: authController);

      expect(ai.requiresAccount, isTrue);
      expect(ai.blockerFor(AiTools.enhance), isNull);
      await ai.run(AiTools.enhance, imagePath: source.path);

      expect(service.requests, isNotEmpty);
    });

    test('an empty balance does not block a run while the credit gate is disabled', () async {
      await signIn();
      final service = FakeAiService();
      final ai = AiStudioController(service: service, auth: authController);
      const expensive = AiTool(
        id: 'expensive',
        name: 'Expensive',
        tagline: '',
        credits: 9999,
      );

      expect(ai.canAfford(expensive), isFalse);
      await ai.run(expensive, imagePath: source.path);

      expect(service.requests, isNotEmpty);
    });

    test('a prompt tool with no prompt never leaves the app', () async {
      await signIn();
      final service = FakeAiService();
      final ai = AiStudioController(service: service, auth: authController);

      await ai.run(AiTools.expand, imagePath: source.path);

      expect(service.requests, isEmpty);
      expect(ai.lastFailure.value?.code, AiFailureCode.promptRequired);
    });

    test('a signed-in account with credits has no blocker', () async {
      await signIn();
      expect(build().blockerFor(AiTools.enhance), isNull);
    });
  });

  group('running', () {
    test('a finished run waits for Apply rather than changing the photo',
        () async {
      await signIn();
      final ai = build();

      await ai.run(AiTools.enhance, imagePath: source.path);

      expect(ai.pendingResult.value, isNotNull);
      expect(ai.pendingResult.value?.status, AiJobStatus.succeeded);
      expect(ai.isProcessing, isFalse);
    });

    test('taking the result clears it, so it cannot be applied twice',
        () async {
      await signIn();
      final ai = build();
      await ai.run(AiTools.enhance, imagePath: source.path);

      expect(ai.takeResult(), isNotNull);
      expect(ai.pendingResult.value, isNull);
      expect(ai.takeResult(), isNull);
    });

    test('discarding drops the result', () async {
      await signIn();
      final ai = build();
      await ai.run(AiTools.enhance, imagePath: source.path);

      ai.discardResult();

      expect(ai.pendingResult.value, isNull);
      expect(ai.activeJob.value, isNull);
    });

    test('a service failure surfaces as a failure, not an exception', () async {
      await signIn();
      final ai = AiStudioController(
        service: FakeAiService(failWith: AiFailureCode.quotaExceeded),
        auth: authController,
      );

      await ai.run(AiTools.enhance, imagePath: source.path);

      expect(ai.lastFailure.value?.code, AiFailureCode.quotaExceeded);
      expect(ai.pendingResult.value, isNull);
    });

    test('the prompt is forwarded to the service', () async {
      await signIn();
      final service = FakeAiService();
      final ai = AiStudioController(service: service, auth: authController);

      await ai.run(AiTools.expand, imagePath: source.path, prompt: 'a wide beach');

      expect(service.requests.single.prompt, 'a wide beach');
    });
  });

  group('applying a result to the editor', () {
    Future<EditorController> openEditor() async {
      final now = DateTime.now();
      final ctrl = EditorController(renderDelay: Duration.zero);
      ctrl.setProject(EditProject(
        id: 'p1',
        name: 'Trip',
        originalPath: source.path,
        width: 50,
        height: 50,
        createdAt: now,
        updatedAt: now,
      ));
      await ctrl.load();
      return ctrl;
    }

    test('applying adds one undoable step and swaps the replay source',
        () async {
      await signIn();
      final ai = build();
      final editor = await openEditor();

      await ai.run(AiTools.enhance, imagePath: source.path);
      final job = ai.takeResult()!;
      await editor.applyAiResult(tool: job.tool, bytes: job.result!);

      expect(editor.history.map((o) => o.label), [AiTools.enhance.name]);
      expect(editor.stack.state.sourcePath, isNotNull);
      expect(editor.effectiveSourcePath, isNot(source.path));
    });

    test('undoing the AI step returns to the untouched original', () async {
      await signIn();
      final ai = build();
      final editor = await openEditor();

      await ai.run(AiTools.enhance, imagePath: source.path);
      final job = ai.takeResult()!;
      await editor.applyAiResult(tool: job.tool, bytes: job.result!);

      await editor.undo();

      expect(editor.stack.state.sourcePath, isNull);
      expect(editor.effectiveSourcePath, source.path);
    });

    test('the original file on disk is never overwritten', () async {
      final before = await source.readAsBytes();
      await signIn();
      final ai = build();
      final editor = await openEditor();

      await ai.run(AiTools.enhance, imagePath: source.path);
      final job = ai.takeResult()!;
      await editor.applyAiResult(tool: job.tool, bytes: job.result!);

      expect(await source.readAsBytes(), before,
          reason: 'an AI run is a step in the stack, not a point of no return');
    });

    test('edits made before the AI step still apply after it', () async {
      await signIn();
      final ai = build();
      final editor = await openEditor();

      editor.setAdjust(brightness: 30);
      await editor.commitAdjust('Brightness');

      await ai.run(AiTools.enhance, imagePath: source.path);
      final job = ai.takeResult()!;
      await editor.applyAiResult(tool: job.tool, bytes: job.result!);

      expect(editor.brightness.value, 30);
      expect(editor.history.map((o) => o.label),
          ['Brightness', AiTools.enhance.name]);
    });
  });
}
