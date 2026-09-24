import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../values/app_colors.dart';
import '../../common_components/tool_slider.dart';
import 'widgets/tool_chip.dart';

/// All four adjustments the controller supports. Previously only Brightness had
/// a control, so contrast/saturation/sharpness were unreachable observables.
class AdjustPanel extends StatefulWidget {
  final EditorController ctrl;

  const AdjustPanel({super.key, required this.ctrl});

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  int _selected = 0;

  static const _controls = ['Brightness', 'Contrast', 'Saturation', 'Sharpness'];

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: Obx(() {
              // Read every slider here in the Obx body. An itemBuilder runs
              // later, outside the tracking scope, so reading them there would
              // subscribe this Obx to nothing at all.
              final values = [
                ctrl.brightness.value,
                ctrl.contrast.value,
                ctrl.saturation.value,
                ctrl.sharpness.value,
              ];
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _controls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => ToolChip(
                  label: _controls[i],
                  active: _selected == i,
                  badge: values[i] != 0,
                  onTap: () => setState(() => _selected = i),
                ),
              );
            }),
          ),
          const SizedBox(height: 4),
          Obx(
            () => ToolSlider(
              compact: true,
              label: _controls[_selected],
              value: _valueFor(ctrl, _selected),
              onChanged: (v) => _onChanged(ctrl, v),
              onChangeEnd: (_) => ctrl.commitAdjust(_controls[_selected]),
              onReset: () {
                _onChanged(ctrl, 0);
                ctrl.commitAdjust(_controls[_selected]);
              },
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: ctrl.resetAdjust,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 15, color: AppColors.textSecondary),
                      SizedBox(width: 4),
                      Text('Reset all',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Obx(() => _AutoButton(
                      running: ctrl.isAutoRunning.value,
                      onTap: ctrl.autoEnhance,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _valueFor(EditorController ctrl, int index) => switch (index) {
        0 => ctrl.brightness.value,
        1 => ctrl.contrast.value,
        2 => ctrl.saturation.value,
        _ => ctrl.sharpness.value,
      };

  void _onChanged(EditorController ctrl, double v) {
    switch (_selected) {
      case 0:
        ctrl.setAdjust(brightness: v);
      case 1:
        ctrl.setAdjust(contrast: v);
      case 2:
        ctrl.setAdjust(saturation: v);
      default:
        ctrl.setAdjust(sharpness: v);
    }
  }
}

/// Auto reads the photo's own histogram and moves the sliders, so the user can
/// see exactly what it did and keep tuning from there.
class _AutoButton extends StatelessWidget {
  const _AutoButton({required this.running, required this.onTap});

  final bool running;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: running ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          gradient: running ? null : AppColors.primaryGradient,
          color: running ? AppColors.disabled : null,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (running)
              const SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                    strokeWidth: 1.8, color: AppColors.surface),
              )
            else
              const Icon(Icons.auto_fix_high, size: 15, color: AppColors.surface),
            const SizedBox(width: 6),
            Text(
              running ? 'Analysing' : 'Auto',
              style: const TextStyle(
                color: AppColors.surface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
