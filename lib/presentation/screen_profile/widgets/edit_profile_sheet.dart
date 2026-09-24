import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/profile_controller.dart';
import '../../../values/app_colors.dart';
import '../../../values/app_strings.dart';
import '../../../values/validators.dart';
import '../../common_components/primary_button.dart';

/// Display name only. Avatar upload needs firebase_storage plus a pick/crop/
/// compress/upload flow and its own Storage rules, so it ships with the
/// export/storage phase rather than blocking auth.
class EditProfileSheet extends StatefulWidget {
  const EditProfileSheet({super.key, required this.controller});

  final ProfileController controller;

  static Future<void> show(ProfileController controller) {
    return Get.bottomSheet<void>(
      EditProfileSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.controller.authUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await widget.controller.saveDisplayName(_nameCtrl.text);
    if (!mounted) return;
    Get.back<void>();
    if (ok) {
      Get.snackbar(
        AppStrings.editProfile,
        AppStrings.profileUpdated,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.disabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              AppStrings.editProfile,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _save(),
              validator: (v) => AppStrings.validationMessage(validateDisplayName(v)),
              decoration: InputDecoration(
                labelText: AppStrings.nameLabel,
                hintText: AppStrings.nameHint,
                filled: true,
                fillColor: AppColors.cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Obx(() => PrimaryButton(
                  label: AppStrings.save,
                  isLoading: widget.controller.isSaving.value,
                  onTap: _save,
                )),
          ],
        ),
      ),
    );
  }
}
