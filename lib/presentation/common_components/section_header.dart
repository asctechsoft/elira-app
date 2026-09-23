import 'package:flutter/material.dart';
import '../../values/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: const Row(
              children: [
                Text('See All', style: TextStyle(color: AppColors.primary, fontSize: 14)),
                SizedBox(width: 2),
                Icon(Icons.chevron_right, color: AppColors.primary, size: 18),
              ],
            ),
          ),
      ],
    );
  }
}
