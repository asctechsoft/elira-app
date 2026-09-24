import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/onboarding_prefs.dart';
import '../values/route_name.dart';
import 'auth_controller.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  AuthController get auth => AuthController.to;

  void onPageChanged(int page) => currentPage.value = page;

  /// There is no separate account-creation step any more: both entry points
  /// land straight on Home. Logging in with a real account happens later,
  /// from Settings.
  Future<void> onGetStarted() => _enterApp();

  /// Signs in anonymously rather than bypassing auth entirely. The guest gets
  /// a real uid, so credits/stats/drafts live at /users/{uid} like every other
  /// user, and logging in later links in place instead of migrating.
  Future<void> onSkip() => _enterApp();

  Future<void> _enterApp() async {
    await OnboardingPrefs.markComplete();
    if (!auth.isSignedIn) {
      final ok = await auth.continueAsGuest();
      if (!ok) return;
    }
    Get.offAllNamed(RouteName.main);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
