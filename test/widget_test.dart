// Screen-level smoke tests. These pump individual screens rather than the whole
// EliraApp: the app's initial route is the splash, whose bootstrap pipeline owns
// Firebase init and a deliberate minimum duration, so pumping it leaves pending
// timers and asserts. Screens are tested against the in-memory auth stack.

import 'package:elira/controller/auth_controller.dart';
import 'package:elira/controller/editor_controller.dart';
import 'package:elira/controller/forgot_password_controller.dart';
import 'package:elira/controller/login_controller.dart';
import 'package:elira/controller/profile_controller.dart';
import 'package:elira/controller/signup_controller.dart';
import 'package:elira/data/auth/fake_auth_service.dart';
import 'package:elira/data/user/in_memory_user_repository.dart';
import 'package:elira/presentation/screen_auth/forgot_password_screen.dart';
import 'package:elira/presentation/screen_auth/login_screen.dart';
import 'package:elira/presentation/screen_auth/signup_screen.dart';
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

  testWidgets('login screen rejects a malformed email before calling auth', (tester) async {
    await _installAuth();
    Get.put(LoginController());

    await tester.pumpWidget(_host(const LoginScreen()));
    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.widgetWithText(GestureDetector, AppStrings.logIn).last);
    await tester.pump();

    expect(find.text(AppStrings.validation['emailInvalid']!), findsOneWidget);
    expect(Get.find<AuthController>().isSignedIn, isFalse);
  });

  testWidgets('login screen shows an ambiguous error for a wrong password', (tester) async {
    await _installAuth();
    Get.put(LoginController());

    await tester.pumpWidget(_host(const LoginScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'existing@example.com');
    await tester.enterText(fields.at(1), 'wrong-password');
    await tester.tap(find.widgetWithText(GestureDetector, AppStrings.logIn).last);
    await tester.pumpAndSettle();

    expect(find.text('Email or password is incorrect.'), findsOneWidget);
  });

  testWidgets('signup blocks submission until the terms are accepted', (tester) async {
    await _installAuth();
    Get.put(SignupController());

    await tester.pumpWidget(_host(const SignupScreen()));
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Linh');
    await tester.enterText(fields.at(1), 'brand-new@example.com');
    await tester.enterText(fields.at(2), 'secret123');
    await tester.enterText(fields.at(3), 'secret123');
    final submit = find.widgetWithText(GestureDetector, AppStrings.createAccount).last;
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('Please accept the terms to continue.'), findsOneWidget);
    expect(Get.find<AuthController>().isSignedIn, isFalse);
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
    expect(find.text('30'), findsOneWidget, reason: 'signup credit grant');

    // The profile page nests a GridView inside the CustomScrollView, so the
    // scrollable has to be named explicitly.
    await tester.scrollUntilVisible(
      find.text(AppStrings.signOut),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(AppStrings.signOut), findsOneWidget);
  });

  testWidgets('profile shows the guest state with an upgrade CTA', (tester) async {
    final auth = await _installAuth();
    await auth.continueAsGuest();
    Get.put(ProfileController());

    await tester.pumpWidget(_host(const ProfileScreen()));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.guestName), findsOneWidget);
    expect(find.text(AppStrings.guestBadge), findsOneWidget);
    expect(find.text(AppStrings.signUpAction), findsOneWidget);
  });
}
