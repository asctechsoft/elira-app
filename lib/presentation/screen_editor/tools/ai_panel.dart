import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class AiPanel extends StatelessWidget {
  const AiPanel({super.key});

  static const _aiTools = [
    (Icons.auto_fix_high, 'AI Enhance', Color(0xFFDCFAF0)),
    (Icons.face_retouching_natural, 'AI Retouch', Color(0xFFEEEAFF)),
    (Icons.cleaning_services, 'Remove BG', Color(0xFFFFECEC)),
    (Icons.open_in_full, 'Expand', Color(0xFFE8F0FF)),
    (Icons.brightness_high, 'Relight', Color(0xFFFFF3DC)),
    (Icons.restore, 'Restore', Color(0xFFE0F7E0)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _aiTools
            .map((t) => GestureDetector(
                  onTap: () {},
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: t.$3, borderRadius: BorderRadius.circular(14)),
                          child: Icon(t.$1, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(t.$2, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
