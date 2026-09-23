import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class RetouchPanel extends StatefulWidget {
  const RetouchPanel({super.key});

  @override
  State<RetouchPanel> createState() => _RetouchPanelState();
}

class _RetouchPanelState extends State<RetouchPanel> {
  int _category = 0;
  int _subTool = 0;
  double _intensity = 70;

  static const _categories = [
    (Icons.water_drop_outlined, 'Skin'),
    (Icons.face_outlined, 'Face'),
    (Icons.visibility_outlined, 'Eyes'),
    (Icons.face_retouching_natural, 'Lips'),
    (Icons.content_cut, 'Hair'),
    (Icons.brush_outlined, 'Makeup'),
  ];

  static const _skinTools = ['Smooth Skin', 'Even Tone', 'Blemish Fix', 'Pores', 'Shine'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category tabs
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _categories
                  .asMap()
                  .entries
                  .map((e) => GestureDetector(
                        onTap: () => setState(() { _category = e.key; _subTool = 0; }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _category == e.key ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: _category == e.key ? Border.all(color: AppColors.primary) : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(e.value.$1, size: 20, color: _category == e.key ? AppColors.primary : AppColors.textSecondary),
                              const SizedBox(height: 2),
                              Text(e.value.$2, style: TextStyle(fontSize: 10, color: _category == e.key ? AppColors.primary : AppColors.textSecondary, fontWeight: _category == e.key ? FontWeight.w600 : FontWeight.w400)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Sub-tools
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _skinTools
                  .asMap()
                  .entries
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _subTool = e.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _subTool == e.key ? AppColors.primary : Colors.grey.shade100,
                          ),
                          child: Text(e.value, style: TextStyle(fontSize: 11, color: _subTool == e.key ? Colors.white : AppColors.textSecondary, fontWeight: _subTool == e.key ? FontWeight.w600 : FontWeight.w400)),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Intensity slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Intensity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                    Text('${_intensity.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.primary)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: Colors.grey.shade200,
                    thumbColor: AppColors.primary,
                    trackHeight: 4,
                  ),
                  child: Slider(value: _intensity, min: 0, max: 100, onChanged: (v) => setState(() => _intensity = v)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(onTap: () => setState(() => _intensity = 0), child: const Row(children: [Icon(Icons.refresh, size: 14, color: AppColors.textSecondary), SizedBox(width: 4), Text('Reset', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
                    const Row(children: [Icon(Icons.auto_awesome, size: 14, color: AppColors.primary), SizedBox(width: 4), Text('Auto', style: TextStyle(color: AppColors.primary, fontSize: 13))]),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
