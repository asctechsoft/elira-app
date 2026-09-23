import 'package:flutter/material.dart';
import '../../values/app_colors.dart';

class ToolSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final VoidCallback? onReset;
  final VoidCallback? onAuto;

  const ToolSlider({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = -100,
    this.max = 100,
    this.onReset,
    this.onAuto,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: Colors.grey.shade200,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.1),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(value: value, min: min, max: max, onChanged: onChanged),
          ),
          if (onReset != null || onAuto != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onReset != null)
                  GestureDetector(
                    onTap: onReset,
                    child: const Row(
                      children: [
                        Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text('Reset',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                if (onAuto != null)
                  GestureDetector(
                    onTap: onAuto,
                    child: const Row(
                      children: [
                        Icon(Icons.auto_fix_high, size: 16, color: AppColors.primary),
                        SizedBox(width: 4),
                        Text('Auto',
                            style: TextStyle(color: AppColors.primary, fontSize: 13)),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
