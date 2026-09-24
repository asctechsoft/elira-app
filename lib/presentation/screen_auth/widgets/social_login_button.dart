import 'package:flutter/material.dart';

import '../../../data/auth/social_provider.dart';
import '../../../values/app_colors.dart';

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onTap,
    this.isLoading = false,
  });

  final SocialAuthProvider provider;
  final VoidCallback? onTap;
  final bool isLoading;

  Color get _badgeColor => switch (provider) {
        SocialAuthProvider.google => const Color(0xFF4285F4),
        SocialAuthProvider.facebook => const Color(0xFF1877F2),
        SocialAuthProvider.tiktok => const Color(0xFF010101),
      };

  String get _glyph => switch (provider) {
        SocialAuthProvider.google => 'G',
        SocialAuthProvider.facebook => 'f',
        SocialAuthProvider.tiktok => 'T',
      };

  @override
  Widget build(BuildContext context) {
    final enabled = !isLoading && onTap != null;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.disabled),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _badgeColor, shape: BoxShape.circle),
              child: Text(
                _glyph,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Continue with ${provider.label}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
