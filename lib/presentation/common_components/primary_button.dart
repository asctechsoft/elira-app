import 'package:flutter/material.dart';
import '../../values/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool isLoading;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? null
              : const LinearGradient(
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
          color: onTap == null ? Colors.grey.shade300 : null,
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
