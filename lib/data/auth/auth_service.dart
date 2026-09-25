import 'auth_user.dart';
import 'social_provider.dart';

abstract class AuthService {
  AuthUser? get currentUser;

  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthUser> signInAnonymously();

  /// Upgrades the current anonymous session in place, keeping the same uid so
  /// credits, drafts and stats survive the conversion.
  Future<AuthUser> linkAnonymousToEmail({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthUser> signInWithSocial(SocialAuthProvider provider);

  /// Upgrades the current anonymous session in place, keeping the same uid so
  /// credits, drafts and stats survive the conversion.
  Future<AuthUser> linkAnonymousToSocial(SocialAuthProvider provider);

  Future<void> sendPasswordResetEmail(String email);

  Future<void> updateDisplayName(String displayName);

  Future<void> updatePhotoUrl(String? url);

  Future<void> reload();

  /// Bearer token for our own backend. The AI service sends this instead of
  /// any provider key: spec 25 keeps the Replicate and remove.bg credentials
  /// server-side, so the app proves who it is and the server decides what that
  /// user is allowed to spend.
  Future<String?> idToken({bool forceRefresh = false});

  Future<void> signOut();

  /// Required by both stores before review; wired now because retrofitting
  /// deletion once credits and projects reference the uid is far more costly.
  Future<void> deleteAccount();
}
