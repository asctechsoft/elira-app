import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class FiltersPanel extends StatefulWidget {
  const FiltersPanel({super.key});

  @override
  State<FiltersPanel> createState() => _FiltersPanelState();
}

class _FiltersPanelState extends State<FiltersPanel> {
  int _selected = 0;
  static const _filters = ['Original', 'Cinematic', 'Vivid', 'Fade', 'Cool', 'Warm', 'B&W', 'Moody'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => setState(() => _selected = i),
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                    border: _selected == i ? Border.all(color: AppColors.primary, width: 2) : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(_filters[i], style: TextStyle(fontSize: 10, color: _selected == i ? AppColors.primary : AppColors.textSecondary, fontWeight: _selected == i ? FontWeight.w600 : FontWeight.w400)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
