import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class BackgroundPanel extends StatefulWidget {
  const BackgroundPanel({super.key});

  @override
  State<BackgroundPanel> createState() => _BackgroundPanelState();
}

class _BackgroundPanelState extends State<BackgroundPanel> {
  int _bgMode = 0; // 0=RemoveBG, 1=Blur, 2=Color, 3=Replace, 4=Shadow
  int _bgPreset = 0;
  double _edgeRefinement = 80;

  static const _bgModes = [
    (Icons.person_outline, 'Remove BG'),
    (Icons.blur_on, 'Blur'),
    (Icons.palette_outlined, 'Color'),
    (Icons.find_replace, 'Replace'),
    (Icons.layers_outlined, 'Shadow'),
  ];

  static const _presets = ['None', 'Studio', 'Beach', 'City', 'Nature', 'Gradient', 'More'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BG presets
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: _presets
                  .asMap()
                  .entries
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _bgPreset = e.key),
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: e.key == 0 ? null : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(10),
                                  border: _bgPreset == e.key ? Border.all(color: AppColors.primary, width: 2) : null,
                                  image: e.key == 0
                                      ? const DecorationImage(
                                          image: AssetImage('assets/images/png/bg_splash.png'),
                                          fit: BoxFit.cover,
                                          opacity: 0.3,
                                        )
                                      : null,
                                ),
                                child: e.key == 0 ? const Icon(Icons.grid_4x4, color: Colors.grey) : null,
                              ),
                              const SizedBox(height: 4),
                              Text(e.value, style: TextStyle(fontSize: 10, color: _bgPreset == e.key ? AppColors.primary : AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Mode tabs
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _bgModes
                  .asMap()
                  .entries
                  .map((e) => GestureDetector(
                        onTap: () => setState(() => _bgMode = e.key),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: _bgMode == e.key ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: _bgMode == e.key ? Border.all(color: AppColors.primary) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(e.value.$1, size: 16, color: _bgMode == e.key ? AppColors.primary : AppColors.textSecondary),
                              const SizedBox(width: 5),
                              Text(e.value.$2, style: TextStyle(fontSize: 12, color: _bgMode == e.key ? AppColors.primary : AppColors.textSecondary, fontWeight: _bgMode == e.key ? FontWeight.w600 : FontWeight.w400)),
                            ],
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          // Edge Refinement slider
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Edge Refinement', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    Text('${_edgeRefinement.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 14)),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.primary, inactiveTrackColor: Colors.grey.shade200, thumbColor: AppColors.primary, trackHeight: 4),
                  child: Slider(value: _edgeRefinement, min: 0, max: 100, onChanged: (v) => setState(() => _edgeRefinement = v)),
                ),
                const Text('Makes cutout edges look more natural.', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(onTap: () => setState(() => _edgeRefinement = 80), child: const Row(children: [Icon(Icons.refresh, size: 14, color: AppColors.textSecondary), SizedBox(width: 4), Text('Reset', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))])),
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
