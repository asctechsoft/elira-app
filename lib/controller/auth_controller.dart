import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/auth/auth_failure.dart';
import '../data/auth/auth_service.dart';
import '../data/auth/auth_user.dart';
import '../data/auth/social_provider.dart';
import '../data/user/user_repository.dart';
import '../models/data_models/app_user.dart';

/// Owns the session. Registered permanently because `signOut()` calls
/// `Get.offAllNamed`, which disposes route-scoped dependencies — a non-permanent
/// registration would make `AuthController.to` throw inside the route guards on
/// the very next navigation.
class AuthController extends GetxService {
  AuthController(this._auth, this._users);

  static AuthController get to => Get.find<AuthController>();

  final AuthService _auth;
  final UserRepository _users;

  final Rxn<AuthUser> firebaseUser = Rxn<AuthUser>();
  final Rxn<AppUser> profile = Rxn<AppUser>();
  final RxBool isBusy = false.obs;
  final Rxn<AuthFailureCode> lastError = Rxn<AuthFailureCode>();

  StreamSubscription<AuthUser?>? _sub;
  String locale = 'en';

  bool get isSignedIn => firebaseUser.value != null;
  bool get isGuest => firebaseUser.value?.isAnonymous ?? false;
  bool get isPro => profile.value?.subscription.isActive ?? false;

  /// Resolves once the persisted session is *known*, which is what avoids the
  /// splash flicker. `currentUser` immediately after init is a race: on a cold
  /// start it can still be null while the plugin is restoring the token.
  Future<void> restoreSession({Duration timeout = const Duration(seconds: 5)}) async {
    AuthUser? restored;
    try {
      restored = await _auth.authStateChanges().first.timeout(timeout);
    } on TimeoutException {
      restored = _auth.currentUser;
    }
    firebaseUser.value = restored;
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = _auth.authStateChanges().listen((user) {
      firebaseUser.value = user;
      if (user == null) profile.value = null;
    });
  }

  /// Non-critical: a missing or unreachable profile document must not block
  /// boot, so failures leave a placeholder derived from the auth session.
  Future<void> loadProfile() async {
    final user = firebaseUser.value;
    if (user == null) return;
    try {
      profile.value = await _users.fetch(user.uid) ?? AppUser.placeholder(user, locale: locale);
    } catch (error) {
      debugPrint('[auth] profile load failed: $error');
      profile.value = AppUser.placeholder(user, locale: locale);
    }
  }

  Future<bool> signInWithEmail(String email, String password) => _run(() async {
        final user = await _auth.signInWithEmail(email: email, password: password);
        await _afterSignIn(user);
      });

  Future<bool> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) =>
      _run(() async {
        // An existing anonymous session is upgraded in place so the guest keeps
        // the same uid, and with it their credits, drafts and stats.
        final user = isGuest
            ? await _auth.linkAnonymousToEmail(
                email: email,
                password: password,
                displayName: name,
              )
            : await _auth.signUpWithEmail(
                email: email,
                password: password,
                displayName: name,
              );
        await _afterSignIn(user);
      });

  Future<bool> continueAsGuest() => _run(() async {
        final user = await _auth.signInAnonymously();
        await _afterSignIn(user);
      });

  Future<bool> signInWithSocial(SocialAuthProvider provider) => _run(() async {
        final user = isGuest
            ? await _auth.linkAnonymousToSocial(provider)
            : await _auth.signInWithSocial(provider);
        await _afterSignIn(user);
      });

  Future<bool> sendPasswordReset(String email) =>
      _run(() => _auth.sendPasswordResetEmail(email));

  Future<bool> updateDisplayName(String name) => _run(() async {
        await _auth.updateDisplayName(name);
        final user = _auth.currentUser;
        if (user != null) {
          firebaseUser.value = user;
          await _users.updateProfile(user.uid, displayName: name.trim());
          profile.value = profile.value?.copyWith(displayName: name.trim());
        }
      });

  Future<void> refreshProfile() async {
    try {
      await _auth.reload();
      final user = _auth.currentUser;
      if (user != null) firebaseUser.value = user;
    } catch (error) {
      debugPrint('[auth] reload failed: $error');
    }
    await loadProfile();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (error) {
      debugPrint('[auth] sign out failed: $error');
    }
    firebaseUser.value = null;
    profile.value = null;
    lastError.value = null;
  }

  Future<void> _afterSignIn(AuthUser user) async {
    firebaseUser.value = user;
    profile.value = await _users.ensureCreated(user, locale: locale);
    // Fire and forget: awaiting a Firestore write while offline never returns.
    unawaited(_users.touchLastLogin(user.uid).catchError((Object e) {
      debugPrint('[auth] touchLastLogin skipped: $e');
    }));
  }

  Future<bool> _run(Future<void> Function() body) async {
    isBusy.value = true;
    lastError.value = null;
    try {
      await body();
      return true;
    } on AuthFailure catch (failure) {
      lastError.value = failure.code;
      return false;
    } catch (error) {
      debugPrint('[auth] unexpected: $error');
      lastError.value = AuthFailureCode.unknown;
      return false;
    } finally {
      isBusy.value = false;
    }
  }

  void clearError() => lastError.value = null;

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
