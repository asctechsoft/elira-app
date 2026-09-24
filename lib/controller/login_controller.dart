import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../values/route_name.dart';
import 'auth_controller.dart';

/// Form state lives here rather than in the permanent AuthController so the
/// TextEditingControllers are disposed with the route instead of leaking for
/// the lifetime of the app and carrying stale text across logout/login.
class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final obscure = true.obs;

  AuthController get auth => AuthController.to;

  void toggleObscure() => obscure.value = !obscure.value;

  Future<void> submit() async {
    auth.clearError();
    if (!(formKey.currentState?.validate() ?? false)) return;
    final ok = await auth.signInWithEmail(emailCtrl.text, passwordCtrl.text);
    if (ok) Get.offAllNamed(RouteName.main);
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    super.onClose();
  }
}
