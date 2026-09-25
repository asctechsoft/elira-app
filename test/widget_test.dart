// Screen-level smoke tests. These pump individual screens rather than the whole
// EliraApp: the app's initial route is the splash, whose bootstrap pipeline owns
// Firebase init and a deliberate minimum duration, so pumping it leaves pending
// timers and asserts. Screens are tested against the in-memory auth stack.

import 'package:elira/controller/auth_controller.dart';
import 'package:elira/controller/editor_controller.dart';
import 'package:elira/controller/forgot_password_controller.dart';
import 'package:elira/controller/login_controller.dart';
import 'package:elira/controller/profile_controller.dart';
import 'package:elira/data/auth/fake_auth_service.dart';
import 'package:elira/data/user/in_memory_user_repository.dart';
import 'package:elira/presentation/screen_auth/forgot_password_screen.dart';
import 'package:elira/presentation/screen_auth/login_screen.dart';
import 'package:elira/presentation/screen_editor/editor_screen.dart';
import 'package:elira/presentation/screen_profile/profile_screen.dart';
import 'package:elira/values/app_strings.dart';
import 'package:elira/values/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<AuthController> _installAuth({FakeAuthService? service}) async {
  final auth = service ?? FakeAuthService(accounts: {'existing@example.com': 'secret123'});
  final controller = AuthController(auth, InMemoryUserRepository());
  await controller.restoreSession();
  Get.put<AuthController>(controller, permanent: true);
  return controller;
}

Widget _host(Widget child) => GetMaterialApp(theme: AppTheme.light, home: child);

void main() {
  tearDown(Get.reset);

  // Regression: Obx wrapping a widget constructor tracks nothing, because the
  // observables are only read later in that widget's own build().
  testWidgets('editor screen builds without an improper-GetX error', (tester) async {
    Get.put(EditorController());

    await tester.pumpWidget(_host(const EditorScreen()));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Original'), findsOneWidget);
  });

  testWidgets('login screen offers only the three social sign-in options', (tester) async {
    await _installAuth();
    Get.put(LoginController());

    await tester.pumpWidget(_host(const LoginScreen()));
    await tester.pump();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Facebook'), findsOneWidget);
    expect(find.text('Continue with TikTok'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('forgot password moves to the sent state', (tester) async {
    await _installAuth();
    Get.put(ForgotPasswordController());

    await tester.pumpWidget(_host(const ForgotPasswordScreen()));
    await tester.enterText(find.byType(TextFormField).first, 'existing@example.com');
    await tester.tap(find.widgetWithText(GestureDetector, AppStrings.sendResetLink).last);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.resetSentTitle), findsOneWidget);
  });

  testWidgets('profile renders the signed-in user, not the old mock data', (tester) async {
    final auth = await _installAuth();
    await auth.signUpWithEmail(
      name: 'Linh Nguyen',
      email: 'linh@example.com',
      password: 'secret123',
    );
    Get.put(ProfileController());

    await tester.pumpWidget(_host(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Linh Nguyen'), findsOneWidget);
    expect(find.text('linh@example.com'), findsOneWidget);
    expect(find.text('Emma Carter'), findsNothing);
    // The AI Credits stat is hidden while FeatureFlags.creditsEnabled is off.

    // The profile page nests a GridView inside the CustomScrollView, so the
    // scrollable has to be named explicitly.
    await tester.scrollUntilVisible(
      find.text(AppStrings.signOut),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.signOut), findsOneWidget);
  });

  testWidgets('profile shows the guest state with a login button', (tester) async {
    final auth = await _installAuth();
    await auth.continueAsGuest();
    Get.put(ProfileController());

    await tester.pumpWidget(_host(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.guestName), findsOneWidget);
    expect(find.text(AppStrings.guestBadge), findsOneWidget);
    expect(find.text(AppStrings.logIn), findsWidgets);
  });
}
