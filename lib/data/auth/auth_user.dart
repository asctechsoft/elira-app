/// Provider-agnostic identity. Keeping `firebase_auth` types out of the
/// service contract is what lets the fake implementation — and every unit
/// test — run without a Firebase binary.
class AuthUser {
  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
    this.emailVerified = false,
    this.providers = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;
  final bool emailVerified;
  final List<String> providers;

  AuthUser copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
    bool? emailVerified,
    List<String>? providers,
  }) {
    return AuthUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      emailVerified: emailVerified ?? this.emailVerified,
      providers: providers ?? this.providers,
    );
  }

  @override
  String toString() => 'AuthUser($uid, anon: $isAnonymous, providers: $providers)';
}
