import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class EffectsPanel extends StatefulWidget {
  const EffectsPanel({super.key});

  @override
  State<EffectsPanel> createState() => _EffectsPanelState();
}

class _EffectsPanelState extends State<EffectsPanel> {
  int _selected = 0;
  static const _effects = ['None', 'Glow', 'Vignette', 'Grain', 'Bokeh', 'Light Leak'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: _effects
            .asMap()
            .entries
            .map((e) => GestureDetector(
                  onTap: () => setState(() => _selected = e.key),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                            border: _selected == e.key ? Border.all(color: AppColors.primary, width: 2) : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(e.value, style: TextStyle(fontSize: 10, color: _selected == e.key ? AppColors.primary : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
