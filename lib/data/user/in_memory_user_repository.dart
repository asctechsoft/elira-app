import 'dart:async';

import '../../models/data_models/app_user.dart';
import '../auth/auth_user.dart';
import 'user_repository.dart';

/// Backs unit tests and the offline dev mode. Mirrors [FirestoreUserRepository]
/// semantics, including the "create once, never re-grant credits" rule.
class InMemoryUserRepository implements UserRepository {
  final Map<String, AppUser> _docs = {};
  final Map<String, StreamController<AppUser?>> _watchers = {};

  @override
  Future<AppUser?> fetch(String uid) async => _docs[uid];

  @override
  Stream<AppUser?> watch(String uid) {
    final controller = _watchers.putIfAbsent(uid, () => StreamController<AppUser?>.broadcast());
    return controller.stream.transform(
      StreamTransformer.fromHandlers(handleData: (data, sink) => sink.add(data)),
    );
  }

  @override
  Future<AppUser> ensureCreated(AuthUser authUser, {required String locale}) async {
    final existing = _docs[authUser.uid];
    if (existing != null) {
      final refreshed = existing.copyWith(
        email: authUser.email,
        displayName: authUser.displayName,
        photoUrl: authUser.photoUrl,
        isAnonymous: authUser.isAnonymous,
        providers: authUser.providers,
      );
      return _put(refreshed);
    }
    return _put(AppUser(
      uid: authUser.uid,
      email: authUser.email,
      displayName: authUser.displayName,
      photoUrl: authUser.photoUrl,
      isAnonymous: authUser.isAnonymous,
      providers: authUser.providers,
      locale: locale,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      credits: const UserCredits(
        balance: UserCredits.signupGrant,
        lifetimeGranted: UserCredits.signupGrant,
      ),
    ));
  }

  @override
  Future<void> touchLastLogin(String uid) async {}

  @override
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
    String? locale,
  }) async {
    final existing = _docs[uid];
    if (existing == null) return;
    _put(existing.copyWith(displayName: displayName, photoUrl: photoUrl, locale: locale));
  }

  @override
  Future<void> requestDeletion(String uid) async {
    final existing = _docs[uid];
    if (existing == null) return;
    _put(existing.copyWith(
      flags: UserFlags(
        onboardingCompleted: existing.flags.onboardingCompleted,
        marketingOptIn: existing.flags.marketingOptIn,
        deletionRequestedAt: DateTime.now(),
      ),
    ));
  }

  AppUser _put(AppUser user) {
    _docs[user.uid] = user;
    _watchers[user.uid]?.add(user);
    return user;
  }
}
