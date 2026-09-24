import 'package:firebase_auth/firebase_auth.dart';

import 'auth_failure.dart';
import 'auth_service.dart';
import 'auth_user.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  AuthUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<String?> idToken({bool forceRefresh = false}) =>
      _guard(() async => _auth.currentUser?.getIdToken(forceRefresh));

  @override
  Stream<AuthUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(() async {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _require(cred.user);
    });
  }

  @override
  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _guard(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(displayName.trim());
      await cred.user?.reload();
      return _require(_auth.currentUser ?? cred.user);
    });
  }

  @override
  Future<AuthUser> signInAnonymously() {
    return _guard(() async {
      final cred = await _auth.signInAnonymously();
      return _require(cred.user);
    });
  }

  @override
  Future<AuthUser> linkAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _guard(() async {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        throw const AuthFailure(
          AuthFailureCode.unknown,
          debugMessage: 'linkAnonymousToEmail called without an anonymous session',
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email.trim(),
        password: password,
      );
      final linked = await user.linkWithCredential(credential);
      await linked.user?.updateDisplayName(displayName.trim());
      await linked.user?.reload();
      return _require(_auth.currentUser ?? linked.user);
    });
  }

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  @override
  Future<void> updateDisplayName(String displayName) {
    return _guard(() async {
      await _auth.currentUser?.updateDisplayName(displayName.trim());
      await _auth.currentUser?.reload();
    });
  }

  @override
  Future<void> updatePhotoUrl(String? url) {
    return _guard(() async {
      await _auth.currentUser?.updatePhotoURL(url);
      await _auth.currentUser?.reload();
    });
  }

  @override
  Future<void> reload() => _guard(() async => _auth.currentUser?.reload());

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());

  @override
  Future<void> deleteAccount() => _guard(() async => _auth.currentUser?.delete());

  AuthUser? _map(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
      emailVerified: user.emailVerified,
      providers: user.isAnonymous
          ? const ['anonymous']
          : user.providerData.map((p) => p.providerId).toList(growable: false),
    );
  }

  AuthUser _require(User? user) {
    final mapped = _map(user);
    if (mapped == null) {
      throw const AuthFailure(AuthFailureCode.unknown, debugMessage: 'Firebase returned a null user');
    }
    return mapped;
  }

  Future<T> _guard<T>(Future<T> Function() body) async {
    try {
      return await body();
    } on AuthFailure {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(AuthFailure.codeFromString(e.code), debugMessage: e.message);
    } catch (e) {
      throw AuthFailure(AuthFailureCode.unknown, debugMessage: e.toString());
    }
  }
}
