import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/login_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_strings.dart';
import '../../values/route_name.dart';
import '../../values/validators.dart';
import '../common_components/primary_button.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

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
        Form(
          key: ctrl.formKey,
          child: Column(
            children: [
              Obx(() => AuthErrorBanner(message: AppStrings.authError(auth.lastError.value))),
              AuthTextField(
                label: AppStrings.emailLabel,
                hint: AppStrings.emailHint,
                controller: ctrl.emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: (v) => AppStrings.validationMessage(validateEmail(v)),
              ),
              Obx(() => AuthTextField(
                    label: AppStrings.passwordLabel,
                    hint: AppStrings.passwordHint,
                    controller: ctrl.passwordCtrl,
                    obscure: ctrl.obscure.value,
                    onToggleObscure: ctrl.toggleObscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onFieldSubmitted: (_) => ctrl.submit(),
                    validator: (v) => AppStrings.validationMessage(validatePassword(v)),
                  )),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Get.toNamed(RouteName.forgotPassword),
            child: const Text(
              AppStrings.forgotPassword,
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Obx(() => PrimaryButton(
              label: AppStrings.logIn,
              isLoading: auth.isBusy.value,
              onTap: ctrl.submit,
            )),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              AppStrings.noAccount,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            TextButton(
              onPressed: () => Get.offNamed(RouteName.signup),
              child: const Text(
                AppStrings.signUpAction,
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
