import 'dart:async';

import 'auth_failure.dart';
import 'auth_service.dart';
import 'auth_user.dart';

/// In-memory [AuthService]. Lives in `lib/` rather than `test/` on purpose: it
/// backs both the unit tests and the offline dev mode the app falls back to
/// when no Firebase config has been provisioned, so the whole auth flow stays
/// clickable before anyone has console access.
class FakeAuthService implements AuthService {
  FakeAuthService({AuthUser? seededUser, Map<String, String>? accounts})
      : _accounts = {...?accounts} {
    _current = seededUser;
    _controller.add(_current);
  }

  final Map<String, String> _accounts;
  final _controller = StreamController<AuthUser?>.broadcast();
  final List<String> sentResetEmails = [];

  AuthUser? _current;
  int _uidCounter = 0;

  @override
  Future<String?> idToken({bool forceRefresh = false}) async =>
      _current == null ? null : 'fake-token-${_current!.uid}';

  @override
  AuthUser? get currentUser => _current;

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts[key] != password) {
      throw const AuthFailure(AuthFailureCode.invalidCredential);
    }
    return _emit(AuthUser(
      uid: 'uid-$key',
      email: key,
      displayName: _displayNames[key],
      providers: const ['password'],
      emailVerified: true,
    ));
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure(AuthFailureCode.emailAlreadyInUse);
    }
    if (password.length < 6) {
      throw const AuthFailure(AuthFailureCode.weakPassword);
    }
    _accounts[key] = password;
    _displayNames[key] = displayName.trim();
    return _emit(AuthUser(
      uid: 'uid-$key',
      email: key,
      displayName: displayName.trim(),
      providers: const ['password'],
    ));
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    _uidCounter++;
    return _emit(AuthUser(
      uid: 'anon-$_uidCounter',
      isAnonymous: true,
      providers: const ['anonymous'],
    ));
  }

  @override
  Future<AuthUser> linkAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final existing = _current;
    if (existing == null || !existing.isAnonymous) {
      throw const AuthFailure(AuthFailureCode.unknown);
    }
    final key = email.trim().toLowerCase();
    if (_accounts.containsKey(key)) {
      throw const AuthFailure(AuthFailureCode.emailAlreadyInUse);
    }
    _accounts[key] = password;
    _displayNames[key] = displayName.trim();
    // Same uid: this is the whole point of linking rather than re-registering.
    return _emit(existing.copyWith(
      email: key,
      displayName: displayName.trim(),
      isAnonymous: false,
      providers: const ['password'],
    ));
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    sentResetEmails.add(email.trim().toLowerCase());
  }

  @override
  Future<void> updateDisplayName(String displayName) async {
    final user = _current;
    if (user == null) return;
    if (user.email != null) _displayNames[user.email!] = displayName.trim();
    _emit(user.copyWith(displayName: displayName.trim()));
  }

  @override
  Future<void> updatePhotoUrl(String? url) async {
    final user = _current;
    if (user == null) return;
    _emit(user.copyWith(photoUrl: url));
  }

  @override
  Future<void> reload() async {}

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _current;
    if (user?.email != null) _accounts.remove(user!.email);
    await signOut();
  }

  final Map<String, String> _displayNames = {};

  AuthUser _emit(AuthUser user) {
    _current = user;
    _controller.add(user);
    return user;
  }

  void dispose() => _controller.close();
}
