import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether onboarding has ever been completed so a returning user
/// lands on Home directly instead of seeing onboarding again — even when the
/// auth session itself did not survive the restart (e.g. the in-memory dev
/// auth stack used before Firebase is configured).
class OnboardingPrefs {
  const OnboardingPrefs._();

  static const _key = 'onboarding_complete';

  static Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  static Future<void> markComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }
}
