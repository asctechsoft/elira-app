import '../data/ai/ai_failure.dart';
import '../data/auth/auth_failure.dart';

/// Plain constants rather than ARB/gen-l10n: the AuthFailureCode -> message map
/// has to be centralised anyway, so this gives the localization seam for free
/// without touching the ~3400 lines of already-hardcoded English in the
/// existing screens. Swap for gen-l10n as its own pass once Vietnamese copy exists.
class AppStrings {
  const AppStrings._();

  static const appName = 'ASC Photo AI';
  static const tagline = 'Edit. Enhance. Create.';

  // Splash
  static const splashLoading = 'LOADING MAGIC...';
  static const splashFailedTitle = 'Could not start';
  static const splashFailedBody =
      'We could not reach our servers. Check your connection and try again.';
  static const retry = 'Try again';
  static const continueOffline = 'Continue offline';

  // Onboarding
  static const skip = 'Skip';
  static const getStarted = 'Get Started';

  // Login
  static const loginTitle = 'Welcome back';
  static const loginSubtitle = 'Log in to pick up where you left off.';
  static const emailLabel = 'Email';
  static const emailHint = 'you@example.com';
  static const passwordLabel = 'Password';
  static const passwordHint = 'At least $_minPw characters';
  static const forgotPassword = 'Forgot password?';
  static const logIn = 'Log in';
  static const orContinueWith = 'Or continue with';

  // Shared with the profile "edit name" sheet.
  static const nameLabel = 'Name';
  static const nameHint = 'How should we call you?';

  // Forgot password
  static const forgotTitle = 'Reset your password';
  static const forgotSubtitle = "Enter your email and we'll send you a reset link.";
  static const sendResetLink = 'Send reset link';
  static const resetSentTitle = 'Check your inbox';
  static String resetSentBody(String email) =>
      'If an account exists for $email, a reset link is on its way.';
  static const backToLogin = 'Back to log in';

  // Profile
  static const guestName = 'Guest';
  static const unnamedUser = 'ASC Creator';
  static const guestBadge = 'Not signed in';
  static const proBadge = 'Pro Member';
  static const freeBadge = 'Free plan';
  static const createFreeAccount = 'Create a free account';
  static const signOut = 'Sign Out';
  static const signOutConfirmTitle = 'Sign out?';
  static const signOutConfirmBody = 'You can log back in at any time.';
  static const cancel = 'Cancel';
  static const editProfile = 'Edit Profile';
  static const save = 'Save';
  static const profileUpdated = 'Profile updated';

  // Validation
  static const Map<String, String> validation = {
    'emailRequired': 'Enter your email address.',
    'emailInvalid': "That doesn't look like a valid email.",
    'passwordRequired': 'Enter your password.',
    'passwordTooShort': 'Password must be at least $_minPw characters.',
    'confirmRequired': 'Re-enter your password.',
    'confirmMismatch': 'Passwords do not match.',
    'nameRequired': 'Enter your name.',
    'nameTooShort': 'Name is too short.',
    'nameTooLong': 'Name is too long.',
  };

  static String? validationMessage(String? key) => key == null ? null : validation[key] ?? key;

  static const String _minPw = '6';

  /// Note: invalidCredential deliberately does not say whether the account
  /// exists. Firebase's Email Enumeration Protection collapses wrong-password
  /// and user-not-found into one code, and telling them apart is the
  /// enumeration vulnerability that protection closes.
  static const Map<AuthFailureCode, String> authErrors = {
    AuthFailureCode.invalidCredential: 'Email or password is incorrect.',
    AuthFailureCode.invalidEmail: "That doesn't look like a valid email.",
    AuthFailureCode.userDisabled: 'This account has been disabled.',
    AuthFailureCode.emailAlreadyInUse: 'That email is already registered.',
    AuthFailureCode.weakPassword: 'Choose a stronger password.',
    AuthFailureCode.requiresRecentLogin: 'Please log in again to continue.',
    AuthFailureCode.tooManyRequests: 'Too many attempts. Try again in a few minutes.',
    AuthFailureCode.network: 'No connection. Check your network and try again.',
    AuthFailureCode.operationNotAllowed: 'This sign-in method is not enabled.',
    AuthFailureCode.credentialAlreadyInUse: 'That email is already linked to another account.',
    AuthFailureCode.cancelled: 'Sign-in was cancelled.',
    AuthFailureCode.notConfigured: 'Accounts are unavailable in this build.',
    AuthFailureCode.unknown: 'Something went wrong. Please try again.',
  };

  static String authError(AuthFailureCode? code) =>
      code == null ? '' : authErrors[code] ?? authErrors[AuthFailureCode.unknown]!;

  /// Kept away from the transport: the provider's own error text never reaches
  /// the user, so swapping Replicate for something else changes nothing here.
  static const Map<AiFailureCode, String> aiErrors = {
    AiFailureCode.notConfigured: 'AI tools are not connected in this build yet.',
    AiFailureCode.network: 'No connection. Check your network and try again.',
    AiFailureCode.unauthorized: 'Create a free account to use AI tools.',
    AiFailureCode.insufficientCredits: "You don't have enough credits for this.",
    AiFailureCode.quotaExceeded: 'AI tools are busy right now. Try again shortly.',
    AiFailureCode.unsupportedImage: 'This photo could not be processed.',
    AiFailureCode.tooLarge: 'This photo is too large to upload.',
    AiFailureCode.imageTooSmall: 'This photo is too small for this tool.',
    AiFailureCode.promptRequired: 'Describe what you want first.',
    AiFailureCode.timeout: 'That took too long. Please try again.',
    AiFailureCode.cancelled: 'Cancelled.',
    AiFailureCode.serverError: 'Something went wrong on our side.',
    AiFailureCode.unknown: 'Something went wrong. Please try again.',
  };

  static String aiError(AiFailureCode? code) =>
      code == null ? '' : aiErrors[code] ?? aiErrors[AiFailureCode.unknown]!;
}
