import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/route_name.dart';
import 'auth_controller.dart';

class SignupController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  final obscure = true.obs;
  final acceptedTerms = false.obs;
  final showTermsError = false.obs;

  AuthController get auth => AuthController.to;

  /// True when an anonymous guest is converting, which changes the copy from
  /// "create an account" to "keep your work".
  bool get isUpgrade => auth.isGuest;

  void toggleObscure() => obscure.value = !obscure.value;

  void setAcceptedTerms(bool value) {
    acceptedTerms.value = value;
    if (value) showTermsError.value = false;
  }

  Future<void> submit() async {
    auth.clearError();
    final formValid = formKey.currentState?.validate() ?? false;
    showTermsError.value = !acceptedTerms.value;
    if (!formValid || !acceptedTerms.value) return;

    final ok = await auth.signUpWithEmail(
      name: nameCtrl.text,
      email: emailCtrl.text,
      password: passwordCtrl.text,
    );
    if (ok) Get.offAllNamed(RouteName.main);
  }

  @override
  void onClose() {
    nameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }
}
