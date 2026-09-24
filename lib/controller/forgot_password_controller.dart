import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'auth_controller.dart';

class ForgotPasswordController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final sentTo = RxnString();

  AuthController get auth => AuthController.to;

  Future<void> submit() async {
    auth.clearError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final email = emailCtrl.text.trim();
    final ok = await auth.sendPasswordReset(email);
    if (ok) sentTo.value = email;
  }

  void reset() {
    sentTo.value = null;
    auth.clearError();
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    super.onClose();
  }
}
