enum AuthFailureCode {
  invalidCredential,
  invalidEmail,
  userDisabled,
  emailAlreadyInUse,
  weakPassword,
  requiresRecentLogin,
  tooManyRequests,
  network,
  operationNotAllowed,
  credentialAlreadyInUse,
  cancelled,
  notConfigured,
  unknown,
}

class AuthFailure implements Exception {
  const AuthFailure(this.code, {this.debugMessage});

  final AuthFailureCode code;
  final String? debugMessage;

  /// Firebase's Email Enumeration Protection (on by default) collapses
  /// wrong-password and user-not-found into invalid-credential. Distinguishing
  /// them again would re-open the account enumeration hole it exists to close,
  /// so all three map to a single code.
  static AuthFailureCode codeFromString(String raw) {
    switch (raw) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-login-credentials':
        return AuthFailureCode.invalidCredential;
      case 'invalid-email':
        return AuthFailureCode.invalidEmail;
      case 'user-disabled':
        return AuthFailureCode.userDisabled;
      case 'email-already-in-use':
        return AuthFailureCode.emailAlreadyInUse;
      case 'weak-password':
        return AuthFailureCode.weakPassword;
      case 'requires-recent-login':
        return AuthFailureCode.requiresRecentLogin;
      case 'too-many-requests':
        return AuthFailureCode.tooManyRequests;
      case 'network-request-failed':
        return AuthFailureCode.network;
      case 'operation-not-allowed':
        return AuthFailureCode.operationNotAllowed;
      case 'credential-already-in-use':
      case 'provider-already-linked':
        return AuthFailureCode.credentialAlreadyInUse;
      case 'web-context-cancelled':
        return AuthFailureCode.cancelled;
      default:
        return AuthFailureCode.unknown;
    }
  }

  @override
  String toString() => 'AuthFailure(${code.name}${debugMessage == null ? '' : ': $debugMessage'})';
}
