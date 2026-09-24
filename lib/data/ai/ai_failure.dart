/// Why an AI run did not produce an image. Mirrors the shape of
/// `AuthFailureCode`: the transport's own error strings never reach the UI,
/// so a provider change cannot alter what the user reads.
enum AiFailureCode {
  /// No backend endpoint is configured in this build.
  notConfigured,

  /// Phone is offline, or the request never reached us.
  network,

  /// Signed out, or the token expired mid-run.
  unauthorized,

  /// The account cannot afford this tool.
  insufficientCredits,

  /// Our own rate limit, or the provider's.
  quotaExceeded,

  /// Decoded fine locally but the model rejected it.
  unsupportedImage,

  /// Over the upload size limit.
  tooLarge,

  /// Below the tool's minimum resolution; refused before spending anything.
  imageTooSmall,

  /// This tool needs a prompt and none was given.
  promptRequired,

  timeout,
  cancelled,
  serverError,
  unknown,
}

class AiFailure implements Exception {
  const AiFailure(this.code, {this.detail});

  final AiFailureCode code;

  /// Diagnostic text for logs. Never shown to the user.
  final String? detail;

  /// Whether offering a Retry button makes sense. Retrying a rejected image or
  /// an empty balance just wastes the user's time.
  bool get isRetryable => switch (code) {
        AiFailureCode.network ||
        AiFailureCode.timeout ||
        AiFailureCode.serverError ||
        AiFailureCode.quotaExceeded =>
          true,
        _ => false,
      };

  /// True when the fix is to buy or earn credits, so the UI can send the user
  /// somewhere useful instead of just apologising.
  bool get needsCredits => code == AiFailureCode.insufficientCredits;

  static AiFailureCode codeFromStatus(int status, {String? body}) {
    if (status == 401 || status == 403) return AiFailureCode.unauthorized;
    if (status == 402) return AiFailureCode.insufficientCredits;
    if (status == 413) return AiFailureCode.tooLarge;
    if (status == 415 || status == 422) return AiFailureCode.unsupportedImage;
    if (status == 429) return AiFailureCode.quotaExceeded;
    if (status >= 500) return AiFailureCode.serverError;
    return AiFailureCode.unknown;
  }

  /// Maps the backend's own `error` string, which is the more specific signal
  /// when the status alone is ambiguous.
  static AiFailureCode codeFromString(String? value) => switch (value) {
        'insufficient_credits' => AiFailureCode.insufficientCredits,
        'quota_exceeded' => AiFailureCode.quotaExceeded,
        'unsupported_image' => AiFailureCode.unsupportedImage,
        'too_large' => AiFailureCode.tooLarge,
        'unauthorized' => AiFailureCode.unauthorized,
        'timeout' => AiFailureCode.timeout,
        'cancelled' => AiFailureCode.cancelled,
        _ => AiFailureCode.serverError,
      };

  @override
  String toString() => 'AiFailure(${code.name}${detail == null ? '' : ': $detail'})';
}
