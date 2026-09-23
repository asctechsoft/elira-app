import 'package:flutter/material.dart';
import '../../values/app_colors.dart';

class AppBarTitle extends StatelessWidget {
  final String subtitle;

  const AppBarTitle({super.key, this.subtitle = 'Turn your moments into magic ✨'});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'ASC ',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.textPrimary,
                ),
              ),
              TextSpan(
                text: 'Photo AI',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
