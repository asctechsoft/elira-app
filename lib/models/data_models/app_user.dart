import '../../data/auth/auth_user.dart';

int _asInt(Object? v, [int fallback = 0]) => v is int ? v : (v is num ? v.toInt() : fallback);
bool _asBool(Object? v, [bool fallback = false]) => v is bool ? v : fallback;
String? _asString(Object? v) => v is String && v.isNotEmpty ? v : null;

DateTime? _asDate(Object? v) {
  if (v is DateTime) return v;
  // Firestore hands back a Timestamp; reading `toDate()` dynamically keeps this
  // model free of a cloud_firestore import so it stays unit-testable.
  try {
    final dynamic d = v;
    final converted = d?.toDate();
    if (converted is DateTime) return converted;
  } catch (_) {}
  return null;
}

Map<String, dynamic> _asMap(Object? v) =>
    v is Map ? v.map((k, value) => MapEntry(k.toString(), value)) : <String, dynamic>{};

class UserCredits {
  const UserCredits({
    this.balance = 0,
    this.lifetimeGranted = 0,
    this.lifetimeSpent = 0,
    this.lastGrantAt,
  });

  static const int signupGrant = 30;

  final int balance;
  final int lifetimeGranted;
  final int lifetimeSpent;
  final DateTime? lastGrantAt;

  factory UserCredits.fromMap(Map<String, dynamic> m) => UserCredits(
        balance: _asInt(m['balance']),
        lifetimeGranted: _asInt(m['lifetimeGranted']),
        lifetimeSpent: _asInt(m['lifetimeSpent']),
        lastGrantAt: _asDate(m['lastGrantAt']),
      );
}

class UserSubscription {
  const UserSubscription({
    this.tier = 'free',
    this.status = 'none',
    this.platform,
    this.productId,
    this.expiresAt,
    this.willRenew = false,
    this.originalTransactionId,
    this.verifiedAt,
  });

  final String tier;
  final String status;
  final String? platform;
  final String? productId;
  final DateTime? expiresAt;
  final bool willRenew;
  final String? originalTransactionId;
  final DateTime? verifiedAt;

  bool get isActive {
    if (tier == 'free') return false;
    if (status != 'active' && status != 'in_grace') return false;
    final until = expiresAt;
    return until == null || until.isAfter(DateTime.now());
  }

  factory UserSubscription.fromMap(Map<String, dynamic> m) => UserSubscription(
        tier: _asString(m['tier']) ?? 'free',
        status: _asString(m['status']) ?? 'none',
        platform: _asString(m['platform']),
        productId: _asString(m['productId']),
        expiresAt: _asDate(m['expiresAt']),
        willRenew: _asBool(m['willRenew']),
        originalTransactionId: _asString(m['originalTransactionId']),
        verifiedAt: _asDate(m['verifiedAt']),
      );
}

class UserStats {
  const UserStats({
    this.projects = 0,
    this.favorites = 0,
    this.exports = 0,
    this.aiRuns = 0,
    this.presets = 0,
  });

  final int projects;
  final int favorites;
  final int exports;
  final int aiRuns;
  final int presets;

  factory UserStats.fromMap(Map<String, dynamic> m) => UserStats(
        projects: _asInt(m['projects']),
        favorites: _asInt(m['favorites']),
        exports: _asInt(m['exports']),
        aiRuns: _asInt(m['aiRuns']),
        presets: _asInt(m['presets']),
      );
}

class UserFlags {
  const UserFlags({
    this.onboardingCompleted = false,
    this.marketingOptIn = false,
    this.deletionRequestedAt,
  });

  final bool onboardingCompleted;
  final bool marketingOptIn;
  final DateTime? deletionRequestedAt;

  factory UserFlags.fromMap(Map<String, dynamic> m) => UserFlags(
        onboardingCompleted: _asBool(m['onboardingCompleted']),
        marketingOptIn: _asBool(m['marketingOptIn']),
        deletionRequestedAt: _asDate(m['deletionRequestedAt']),
      );
}

class AppUser {
  const AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.providers = const [],
    this.locale = 'en',
    this.createdAt,
    this.lastLoginAt,
    this.credits = const UserCredits(),
    this.subscription = const UserSubscription(),
    this.stats = const UserStats(),
    this.flags = const UserFlags(),
    this.schemaVersion = currentSchemaVersion,
  });

  static const int currentSchemaVersion = 1;

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final List<String> providers;
  final String locale;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;
  final UserCredits credits;
  final UserSubscription subscription;
  final UserStats stats;
  final UserFlags flags;
  final int schemaVersion;

  /// Every field is defaulted: a document written by a newer server build, or
  /// one left half-written by an interrupted signup, must render rather than
  /// crash the Profile tab.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: _asString(map['uid']) ?? uid,
        email: _asString(map['email']),
        displayName: _asString(map['displayName']),
        photoUrl: _asString(map['photoUrl']),
        isAnonymous: _asBool(map['isAnonymous']),
        providers: (map['providers'] is List)
            ? (map['providers'] as List).map((e) => e.toString()).toList(growable: false)
            : const [],
        locale: _asString(map['locale']) ?? 'en',
        createdAt: _asDate(map['createdAt']),
        lastLoginAt: _asDate(map['lastLoginAt']),
        credits: UserCredits.fromMap(_asMap(map['credits'])),
        subscription: UserSubscription.fromMap(_asMap(map['subscription'])),
        stats: UserStats.fromMap(_asMap(map['stats'])),
        flags: UserFlags.fromMap(_asMap(map['flags'])),
        schemaVersion: _asInt(map['schemaVersion'], currentSchemaVersion),
      );

  /// Used when the auth session is known but the profile document is not
  /// readable yet (offline cold cache, or a create that has not landed).
  factory AppUser.placeholder(AuthUser authUser, {String locale = 'en'}) => AppUser(
        uid: authUser.uid,
        email: authUser.email,
        displayName: authUser.displayName,
        photoUrl: authUser.photoUrl,
        isAnonymous: authUser.isAnonymous,
        providers: authUser.providers,
        locale: locale,
      );

  AppUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    List<String>? providers,
    String? locale,
    UserCredits? credits,
    UserSubscription? subscription,
    UserStats? stats,
    UserFlags? flags,
  }) =>
      AppUser(
        uid: uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        providers: providers ?? this.providers,
        locale: locale ?? this.locale,
        createdAt: createdAt,
        lastLoginAt: lastLoginAt,
        credits: credits ?? this.credits,
        subscription: subscription ?? this.subscription,
        stats: stats ?? this.stats,
        flags: flags ?? this.flags,
        schemaVersion: schemaVersion,
      );
}
