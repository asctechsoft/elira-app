import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../values/app_colors.dart';
import '../../common_components/tool_slider.dart';
import 'widgets/tool_chip.dart';

/// Effects stack rather than replace one another: vignette, grain, blur and
/// glow each keep their own intensity, so a grainy vignette is one state and
/// not a choice between two.
class EffectsPanel extends StatefulWidget {
  const EffectsPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  State<EffectsPanel> createState() => _EffectsPanelState();
}

enum _Effect { vignette, blur, grain, glow, sharpen }

class _EffectsPanelState extends State<EffectsPanel> {
  _Effect _selected = _Effect.vignette;

  static const _labels = {
    _Effect.vignette: 'Vignette',
    _Effect.blur: 'Blur',
    _Effect.grain: 'Grain',
    _Effect.glow: 'Glow',
    _Effect.sharpen: 'Sharpen',
  };

  static const _icons = {
    _Effect.vignette: Icons.vignette_outlined,
    _Effect.blur: Icons.blur_on,
    _Effect.grain: Icons.grain,
    _Effect.glow: Icons.wb_twilight,
    _Effect.sharpen: Icons.details,
  };

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
              // Read every value here in the Obx body: an itemBuilder runs
              // later, outside the tracking scope, so reading them there would
              // subscribe this Obx to nothing at all.
              final values = {
                for (final effect in _Effect.values) effect: _valueOf(ctrl, effect),
              };
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _Effect.values.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final effect = _Effect.values[i];
                  return ToolChip(
                    label: _labels[effect]!,
                    icon: _icons[effect],
                    active: _selected == effect,
                    badge: values[effect] != 0,
                    onTap: () => setState(() => _selected = effect),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 4),
          Obx(
            () => ToolSlider(
              compact: true,
              label: _labels[_selected]!,
              // Sharpen is the only one that runs both ways: below zero it
              // softens, which is the same parameter the Adjust tab exposes.
              min: _selected == _Effect.sharpen ? -100 : 0,
              max: 100,
              value: _valueOf(ctrl, _selected),
              onChanged: (v) => _set(ctrl, _selected, v),
              onChangeEnd: (_) => _commit(ctrl, _selected),
              onReset: () {
                _set(ctrl, _selected, 0);
                _commit(ctrl, _selected);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _hintFor(_selected),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ),
                GestureDetector(
                  onTap: ctrl.clearEffects,
                  child: const Text(
                    'Clear all',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _hintFor(_Effect effect) => switch (effect) {
        _Effect.vignette => 'Darkens the corners to draw the eye inward.',
        _Effect.blur => 'Softens the whole frame.',
        _Effect.grain => 'Adds film-like texture.',
        _Effect.glow => 'Blooms the highlights for a dreamy look.',
        _Effect.sharpen => 'Below zero softens; above zero adds detail.',
      };

  double _valueOf(EditorController ctrl, _Effect effect) => switch (effect) {
        _Effect.vignette => ctrl.vignette.value,
        _Effect.blur => ctrl.blur.value,
        _Effect.grain => ctrl.grain.value,
        _Effect.glow => ctrl.glow.value,
        _Effect.sharpen => ctrl.sharpness.value,
      };

  void _set(EditorController ctrl, _Effect effect, double v) {
    switch (effect) {
      case _Effect.vignette:
        ctrl.setEffect(vignette: v);
      case _Effect.blur:
        ctrl.setEffect(blur: v);
      case _Effect.grain:
        ctrl.setEffect(grain: v);
      case _Effect.glow:
        ctrl.setEffect(glow: v);
      case _Effect.sharpen:
        ctrl.setAdjust(sharpness: v);
    }
  }

  // Sharpen commits as an Adjust operation because it *is* the Adjust tab's
  // sharpness — one parameter with two ways in, never two that can disagree.
  void _commit(EditorController ctrl, _Effect effect) => effect == _Effect.sharpen
      ? ctrl.commitAdjust('Sharpness')
      : ctrl.commitEffects(_labels[effect]!);
}
