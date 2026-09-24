import 'package:flutter/material.dart';
import '../../values/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool isLoading;
  final bool enabled;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.height = 56,
  });

  /// Appearance has to track the loading state too: previously only a null
  /// onTap greyed the button out, so a button that was busy still looked
  /// tappable while silently swallowing taps.
  bool get _isInteractive => enabled && !isLoading && onTap != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isInteractive ? onTap : null,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: (enabled && onTap != null)
              ? const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                )
              : null,
          color: (enabled && onTap != null) ? null : AppColors.disabled,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icon != null) ...[const SizedBox(width: 8), icon!],
                ],
              ),
      ),
    );
  }
}
