import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/route_name.dart';
import 'auth_controller.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  AuthController get auth => AuthController.to;

  void onPageChanged(int page) => currentPage.value = page;

  /// `toNamed`, not `offAllNamed`: the user must be able to come back to
  /// onboarding from signup.
  void onGetStarted() => Get.toNamed(RouteName.signup);

  void onLogIn() => Get.toNamed(RouteName.login);

  /// Skip signs in anonymously rather than bypassing auth entirely. The guest
  /// gets a real uid, so credits/stats/drafts live at /users/{uid} like every
  /// other user, and signing up later links in place instead of migrating.
  Future<void> onSkip() async {
    if (auth.isSignedIn) {
      Get.offAllNamed(RouteName.main);
      return;
    }
    final ok = await auth.continueAsGuest();
    if (ok) Get.offAllNamed(RouteName.main);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
