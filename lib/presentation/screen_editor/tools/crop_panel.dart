import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class CropPanel extends StatefulWidget {
  const CropPanel({super.key});

  @override
  State<CropPanel> createState() => _CropPanelState();
}

class _CropPanelState extends State<CropPanel> {
  int _selectedRatio = 0;
  static const _ratios = ['Free', '1:1', '4:3', '16:9', '3:4', '9:16'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _ratios
                .asMap()
                .entries
                .map((e) => GestureDetector(
                      onTap: () => setState(() => _selectedRatio = e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _selectedRatio == e.key ? AppColors.primary : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(e.value,
                            style: TextStyle(
                              color: _selectedRatio == e.key ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            )),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
