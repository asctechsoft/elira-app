import 'package:elira/data/auth/auth_user.dart';
import 'package:elira/models/data_models/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser.fromMap', () {
    test('survives a completely empty document', () {
      final user = AppUser.fromMap('u1', const {});
      expect(user.uid, 'u1');
      expect(user.email, isNull);
      expect(user.locale, 'en');
      expect(user.credits.balance, 0);
      expect(user.subscription.tier, 'free');
      expect(user.stats.projects, 0);
      expect(user.flags.onboardingCompleted, isFalse);
      expect(user.schemaVersion, AppUser.currentSchemaVersion);
    });

    test('survives wrong types without throwing', () {
      final user = AppUser.fromMap('u1', const {
        'email': 42,
        'displayName': [],
        'providers': 'password',
        'credits': 'not-a-map',
        'stats': 7,
        'schemaVersion': 'x',
      });
      expect(user.email, isNull);
      expect(user.displayName, isNull);
      expect(user.providers, isEmpty);
      expect(user.credits.balance, 0);
      expect(user.stats.projects, 0);
      expect(user.schemaVersion, AppUser.currentSchemaVersion);
    });

    test('reads a well-formed document', () {
      final user = AppUser.fromMap('u1', const {
        'uid': 'u1',
        'email': 'a@b.co',
        'displayName': 'Linh',
        'isAnonymous': false,
        'providers': ['password'],
        'locale': 'vi',
        'credits': {'balance': 30, 'lifetimeGranted': 30, 'lifetimeSpent': 0},
        'subscription': {'tier': 'pro', 'status': 'active'},
        'stats': {'projects': 3, 'favorites': 2, 'exports': 1, 'aiRuns': 5},
        'flags': {'onboardingCompleted': true},
        'schemaVersion': 1,
      });
      expect(user.displayName, 'Linh');
      expect(user.locale, 'vi');
      expect(user.credits.balance, 30);
      expect(user.stats.aiRuns, 5);
      expect(user.flags.onboardingCompleted, isTrue);
    });
  });

  group('UserSubscription.isActive', () {
    test('free tier is never active', () {
      expect(const UserSubscription(tier: 'free', status: 'active').isActive, isFalse);
    });

    test('paid tier needs an active or grace status', () {
      expect(const UserSubscription(tier: 'pro', status: 'active').isActive, isTrue);
      expect(const UserSubscription(tier: 'pro', status: 'in_grace').isActive, isTrue);
      expect(const UserSubscription(tier: 'pro', status: 'expired').isActive, isFalse);
      expect(const UserSubscription(tier: 'pro', status: 'refunded').isActive, isFalse);
    });

    test('an elapsed expiry revokes access even while status says active', () {
      final expired = UserSubscription(
        tier: 'pro',
        status: 'active',
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(expired.isActive, isFalse);

      final live = UserSubscription(
        tier: 'pro',
        status: 'active',
        expiresAt: DateTime.now().add(const Duration(days: 1)),
      );
      expect(live.isActive, isTrue);
    });
  });

  test('AppUser.placeholder mirrors the auth session', () {
    const authUser = AuthUser(
      uid: 'anon-1',
      isAnonymous: true,
      providers: ['anonymous'],
    );
    final user = AppUser.placeholder(authUser);
    expect(user.uid, 'anon-1');
    expect(user.isAnonymous, isTrue);
    expect(user.credits.balance, 0);
    expect(user.subscription.isActive, isFalse);
  });
}
