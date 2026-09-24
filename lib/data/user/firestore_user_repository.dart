import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/data_models/app_user.dart';
import '../auth/auth_user.dart';
import 'user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('users').doc(uid);

  @override
  Future<AppUser?> fetch(String uid) async {
    final snap = await _doc(uid).get();
    final data = snap.data();
    if (!snap.exists || data == null) return null;
    return AppUser.fromMap(uid, data);
  }

  @override
  Stream<AppUser?> watch(String uid) => _doc(uid).snapshots().map((snap) {
        final data = snap.data();
        if (!snap.exists || data == null) return null;
        return AppUser.fromMap(uid, data);
      });

  @override
  Future<AppUser> ensureCreated(AuthUser authUser, {required String locale}) async {
    final ref = _doc(authUser.uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) {
        tx.update(ref, {
          'email': authUser.email,
          'displayName': authUser.displayName,
          'photoUrl': authUser.photoUrl,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return;
      }
      tx.set(ref, _createPayload(authUser, locale));
    });

    // Read back from the server so the credit grant written by the transaction
    // is what the UI shows, not an optimistic local guess.
    final created = await fetch(authUser.uid);
    return created ?? AppUser.placeholder(authUser, locale: locale);
  }

  Map<String, dynamic> _createPayload(AuthUser authUser, String locale) => {
        'uid': authUser.uid,
        'email': authUser.email,
        'displayName': authUser.displayName,
        'photoUrl': authUser.photoUrl,
        'isAnonymous': authUser.isAnonymous,
        'providers': authUser.providers,
        'locale': locale,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'credits': {
          'balance': UserCredits.signupGrant,
          'lifetimeGranted': UserCredits.signupGrant,
          'lifetimeSpent': 0,
          'lastGrantAt': FieldValue.serverTimestamp(),
        },
        'subscription': {
          'tier': 'free',
          'status': 'none',
          'platform': null,
          'productId': null,
          'expiresAt': null,
          'willRenew': false,
          'originalTransactionId': null,
          'verifiedAt': null,
        },
        'stats': {'projects': 0, 'favorites': 0, 'exports': 0, 'aiRuns': 0, 'presets': 0},
        'flags': {
          'onboardingCompleted': false,
          'marketingOptIn': false,
          'deletionRequestedAt': null,
        },
        'schemaVersion': AppUser.currentSchemaVersion,
      };

  @override
  Future<void> touchLastLogin(String uid) {
    // Deliberately not awaited by callers: with offline persistence enabled a
    // write never completes until the server acknowledges it, so awaiting this
    // in the boot path would hang the splash in airplane mode.
    return _doc(uid).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateProfile(
    String uid, {
    String? displayName,
    String? photoUrl,
    String? locale,
  }) {
    final payload = <String, dynamic>{'updatedAt': FieldValue.serverTimestamp()};
    if (displayName != null) payload['displayName'] = displayName;
    if (photoUrl != null) payload['photoUrl'] = photoUrl;
    if (locale != null) payload['locale'] = locale;
    return _doc(uid).update(payload);
  }

  @override
  Future<void> requestDeletion(String uid) => _doc(uid).update({
        'flags.deletionRequestedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
}
