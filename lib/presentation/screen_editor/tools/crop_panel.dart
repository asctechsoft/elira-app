import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../values/app_colors.dart';
import 'widgets/tool_chip.dart';

/// Ratio presets, rotation and mirroring. The box itself lives on the canvas
/// as [CropOverlay]; this panel only sets and confirms it, so the photo is
/// never re-rendered until Apply.
class CropPanel extends StatelessWidget {
  const CropPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  /// Null is free-form. Values are width / height of the finished crop.
  static const List<(String, double?)> _ratios = [
    ('Free', null),
    ('1:1', 1),
    ('4:3', 4 / 3),
    ('16:9', 16 / 9),
    ('3:4', 3 / 4),
    ('9:16', 9 / 16),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: Obx(() {
              // Read here in the Obx body: an itemBuilder runs later, outside
              // the tracking scope, so reading it there would subscribe this
              // Obx to nothing at all.
              final active = ctrl.cropRatio.value;
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _ratios.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final (label, ratio) = _ratios[i];
                  return ToolChip(
                    label: label,
                    active: active == ratio,
                    onTap: () => ctrl.setCropRatio(ratio),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _IconAction(
                icon: Icons.rotate_90_degrees_cw_outlined,
                label: 'Rotate',
                onTap: ctrl.rotate,
              ),
              _IconAction(
                icon: Icons.flip,
                label: 'Flip H',
                onTap: ctrl.flipHorizontal,
              ),
              _IconAction(
                icon: Icons.flip,
                label: 'Flip V',
                quarterTurns: 1,
                onTap: ctrl.flipVertical,
              ),
              _IconAction(
                icon: Icons.crop_free,
                label: 'Reset',
                onTap: ctrl.resetCrop,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: GestureDetector(
                onTap: ctrl.applyCrop,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(23),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: AppColors.surface, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Apply Crop',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.quarterTurns = 0,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final int quarterTurns;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RotatedBox(
              quarterTurns: quarterTurns,
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
