import 'package:elira/controller/auth_controller.dart';
import 'package:elira/data/auth/auth_failure.dart';
import 'package:elira/data/auth/fake_auth_service.dart';
import 'package:elira/data/user/in_memory_user_repository.dart';
import 'package:elira/models/data_models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthService auth;
  late InMemoryUserRepository users;
  late AuthController controller;

  setUp(() {
    auth = FakeAuthService(accounts: {'existing@example.com': 'secret123'});
    users = InMemoryUserRepository();
    controller = AuthController(auth, users);
  });

  tearDown(() {
    controller.onClose();
    auth.dispose();
  });

  test('restoreSession resolves to signed out when no session exists', () async {
    await controller.restoreSession();
    expect(controller.isSignedIn, isFalse);
    expect(controller.isGuest, isFalse);
  });

  test('sign up creates the profile with the signup credit grant', () async {
    await controller.restoreSession();
    final ok = await controller.signUpWithEmail(
      name: 'Linh',
      email: 'new@example.com',
      password: 'secret123',
    );

    expect(ok, isTrue);
    expect(controller.isSignedIn, isTrue);
    expect(controller.profile.value?.credits.balance, UserCredits.signupGrant);
    expect(controller.profile.value?.displayName, 'Linh');
    expect(controller.isPro, isFalse);
  });

  test('a returning user keeps their balance: ensureCreated does not re-grant', () async {
    await controller.restoreSession();
    await controller.signUpWithEmail(
      name: 'Linh',
      email: 'new@example.com',
      password: 'secret123',
    );
    final uid = controller.firebaseUser.value!.uid;

    // Simulate spending before the next login.
    final spent = (await users.fetch(uid))!.copyWith(credits: const UserCredits(balance: 5));
    await users.ensureCreated(controller.firebaseUser.value!, locale: 'en');
    expect(spent.credits.balance, 5);

    await controller.signOut();
    final ok = await controller.signInWithEmail('new@example.com', 'secret123');

    expect(ok, isTrue);
    expect(controller.firebaseUser.value?.uid, uid, reason: 'same account, same uid');
    expect(
      controller.profile.value?.credits.balance,
      UserCredits.signupGrant,
      reason: 'balance comes from the stored document, not a fresh grant',
    );
  });

  test('wrong password surfaces a single ambiguous error code', () async {
    await controller.restoreSession();
    final ok = await controller.signInWithEmail('existing@example.com', 'wrong');
    expect(ok, isFalse);
    expect(controller.lastError.value, AuthFailureCode.invalidCredential);
    expect(controller.isSignedIn, isFalse);
  });

  test('signing up with a taken email reports emailAlreadyInUse', () async {
    await controller.restoreSession();
    final ok = await controller.signUpWithEmail(
      name: 'Linh',
      email: 'existing@example.com',
      password: 'secret123',
    );
    expect(ok, isFalse);
    expect(controller.lastError.value, AuthFailureCode.emailAlreadyInUse);
  });

  test('guest upgrade keeps the same uid instead of creating a second account', () async {
    await controller.restoreSession();
    await controller.continueAsGuest();
    expect(controller.isGuest, isTrue);
    final guestUid = controller.firebaseUser.value!.uid;

    final ok = await controller.signUpWithEmail(
      name: 'Linh',
      email: 'converted@example.com',
      password: 'secret123',
    );

    expect(ok, isTrue);
    expect(controller.isGuest, isFalse);
    expect(controller.firebaseUser.value!.uid, guestUid);
    expect(controller.profile.value?.email, 'converted@example.com');
  });

  test('sign out clears both the session and the cached profile', () async {
    await controller.restoreSession();
    await controller.signUpWithEmail(
      name: 'Linh',
      email: 'new@example.com',
      password: 'secret123',
    );
    await controller.signOut();

    expect(controller.isSignedIn, isFalse);
    expect(controller.profile.value, isNull);
    expect(controller.lastError.value, isNull);
  });

  test('password reset succeeds and clears any prior error', () async {
    await controller.restoreSession();
    await controller.signInWithEmail('existing@example.com', 'wrong');
    expect(controller.lastError.value, isNotNull);

    final ok = await controller.sendPasswordReset('existing@example.com');
    expect(ok, isTrue);
    expect(controller.lastError.value, isNull);
    expect(auth.sentResetEmails, contains('existing@example.com'));
  });

  test('isBusy is released even when the call fails', () async {
    await controller.restoreSession();
    await controller.signInWithEmail('existing@example.com', 'wrong');
    expect(controller.isBusy.value, isFalse);
  });
}
