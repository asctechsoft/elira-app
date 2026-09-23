import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class TextPanel extends StatelessWidget {
  const TextPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Add text button
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(24)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text('Add Text', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Font style row
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['Aa', 'Bb', 'Cc', 'Dd', 'Ee'].map((f) => Container(
                margin: const EdgeInsets.only(right: 10),
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text(f, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
