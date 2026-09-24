/// Where the app finds our AI backend.
///
/// There is deliberately **no API key here and nowhere else in the app**. Spec
/// 25 requires the Replicate and remove.bg credentials to live server-side; an
/// app binary is a public artefact, and a key shipped inside one is a key that
/// has been published. All this holds is the address of our own service, which
/// authenticates the user with their Firebase ID token and decides what they
/// are allowed to spend.
class AiConfig {
  const AiConfig._();

  /// Passed at build time, e.g.
  /// `flutter build apk --flavor product --dart-define=ELIRA_AI_ENDPOINT=https://api.example.com`
  ///
  /// A `--dart-define` rather than a flavor constant because the backend URL
  /// changes between a local server, staging and production independently of
  /// which flavor is being built.
  static const String endpoint =
      String.fromEnvironment('ELIRA_AI_ENDPOINT', defaultValue: '');

  static bool get isConfigured => endpoint.isNotEmpty;

  /// How long to keep polling one job before giving up. Generous: an upscale
  /// of a large photo genuinely takes a while, and timing out early would
  /// abandon a run the user has already been charged for.
  static const Duration jobTimeout = Duration(minutes: 3);

  /// Gap between status polls.
  static const Duration pollInterval = Duration(milliseconds: 1500);

  /// Single request timeout for submit and status calls.
  static const Duration requestTimeout = Duration(seconds: 30);

  /// Refuse locally rather than spending an upload on something the server
  /// will reject anyway.
  static const int maxUploadBytes = 12 * 1024 * 1024;
}
