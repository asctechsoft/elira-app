import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/signup_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_strings.dart';
import '../../values/route_name.dart';
import '../../values/validators.dart';
import '../common_components/primary_button.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<SignupController>();
    final auth = ctrl.auth;
    final upgrading = ctrl.isUpgrade;

    return AuthScaffold(
      title: upgrading ? AppStrings.signupTitleUpgrade : AppStrings.signupTitle,
      subtitle: upgrading ? AppStrings.signupSubtitleUpgrade : AppStrings.signupSubtitle,
      children: [
        Form(
          key: ctrl.formKey,
          child: Column(
            children: [
              Obx(() => AuthErrorBanner(message: AppStrings.authError(auth.lastError.value))),
              AuthTextField(
                label: AppStrings.nameLabel,
                hint: AppStrings.nameHint,
                controller: ctrl.nameCtrl,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (v) => AppStrings.validationMessage(validateDisplayName(v)),
              ),
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
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => AppStrings.validationMessage(validatePassword(v)),
                  )),
              Obx(() => AuthTextField(
                    label: AppStrings.confirmPasswordLabel,
                    controller: ctrl.confirmCtrl,
                    obscure: ctrl.obscure.value,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => ctrl.submit(),
                    validator: (v) => AppStrings.validationMessage(
                      validateConfirmPassword(v, ctrl.passwordCtrl.text),
                    ),
                  )),
            ],
          ),
        ),
        Obx(() => _TermsCheckbox(
              value: ctrl.acceptedTerms.value,
              showError: ctrl.showTermsError.value,
              onChanged: ctrl.setAcceptedTerms,
            )),
        const SizedBox(height: 20),
        Obx(() => PrimaryButton(
              label: AppStrings.createAccount,
              isLoading: auth.isBusy.value,
              onTap: ctrl.submit,
            )),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              AppStrings.alreadyHaveAccount,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            TextButton(
              onPressed: () => Get.offNamed(RouteName.login),
              child: const Text(
                AppStrings.logInAction,
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.value,
    required this.showError,
    required this.onChanged,
  });

  final bool value;
  final bool showError;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: value,
                    onChanged: (v) => onChanged(v ?? false),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Text(
                      AppStrings.acceptTerms,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showError)
          const Padding(
            padding: EdgeInsets.only(left: 34, top: 2),
            child: Text(
              'Please accept the terms to continue.',
              style: TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
      ],
    );
  }
}
