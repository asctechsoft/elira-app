/// Temporary switch for the current demo/dev phase: every editing and AI tool
/// is unlocked and credit balances/prices are hidden from the UI, since
/// pricing and the real AI backend are not ready yet. Flip back to true once
/// they are — every place this is read is found by searching this file's name.
class FeatureFlags {
  const FeatureFlags._();

  static const bool creditsEnabled = false;
}
