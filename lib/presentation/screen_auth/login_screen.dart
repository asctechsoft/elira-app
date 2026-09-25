import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/login_controller.dart';
import '../../data/auth/social_provider.dart';
import '../../values/app_strings.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/social_login_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<LoginController>();
    final auth = ctrl.auth;

    return AuthScaffold(
      title: AppStrings.loginTitle,
      subtitle: AppStrings.loginSubtitle,
      children: [
        Obx(() => AuthErrorBanner(message: AppStrings.authError(auth.lastError.value))),
        Obx(() => SocialLoginButton(
              provider: SocialAuthProvider.google,
              isLoading: auth.isBusy.value,
              onTap: () => ctrl.signInWithSocial(SocialAuthProvider.google),
            )),
        const SizedBox(height: 10),
        Obx(() => SocialLoginButton(
              provider: SocialAuthProvider.facebook,
              isLoading: auth.isBusy.value,
              onTap: () => ctrl.signInWithSocial(SocialAuthProvider.facebook),
            )),
        const SizedBox(height: 10),
        Obx(() => SocialLoginButton(
              provider: SocialAuthProvider.tiktok,
              isLoading: auth.isBusy.value,
              onTap: () => ctrl.signInWithSocial(SocialAuthProvider.tiktok),
            )),
      ],
    );
  }
}
