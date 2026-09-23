import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OnboardingController extends GetxController {
  final pageController = PageController();
  final currentPage = 0.obs;

  void onPageChanged(int page) => currentPage.value = page;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
