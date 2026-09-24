import '../../models/data_models/app_user.dart';
import '../auth/auth_user.dart';

abstract class UserRepository {
  Future<AppUser?> fetch(String uid);

  Stream<AppUser?> watch(String uid);

  /// Creates `/users/{uid}` only when it does not already exist. Must be
  /// idempotent: a plain `set(merge: true)` carrying the signup credit grant
  /// would reset a returning user's balance on every login.
  Future<AppUser> ensureCreated(AuthUser authUser, {required String locale});

  Future<void> touchLastLogin(String uid);

  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
    String? locale,
  });

  Future<void> requestDeletion(String uid);
}
