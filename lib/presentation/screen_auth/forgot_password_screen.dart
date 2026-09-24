import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/forgot_password_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_strings.dart';
import '../../values/validators.dart';
import '../common_components/primary_button.dart';
import 'widgets/auth_error_banner.dart';
import 'widgets/auth_scaffold.dart';
import 'widgets/auth_text_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ForgotPasswordController>();
    final auth = ctrl.auth;

    return Obx(() {
      final sentTo = ctrl.sentTo.value;
      if (sentTo != null) {
        return AuthScaffold(
          title: AppStrings.resetSentTitle,
          subtitle: AppStrings.resetSentBody(sentTo),
          children: [
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: AppColors.success),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Follow the link in the email to choose a new password.',
                      style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            PrimaryButton(label: AppStrings.backToLogin, onTap: Get.back),
          ],
        );
      }

      return AuthScaffold(
        title: AppStrings.forgotTitle,
        subtitle: AppStrings.forgotSubtitle,
        children: [
          Form(
            key: ctrl.formKey,
            child: Column(
              children: [
                AuthErrorBanner(message: AppStrings.authError(auth.lastError.value)),
                AuthTextField(
                  label: AppStrings.emailLabel,
                  hint: AppStrings.emailHint,
                  controller: ctrl.emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.email],
                  onFieldSubmitted: (_) => ctrl.submit(),
                  validator: (v) => AppStrings.validationMessage(validateEmail(v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: AppStrings.sendResetLink,
            isLoading: auth.isBusy.value,
            onTap: ctrl.submit,
          ),
        ],
      );
    });
  }
}
