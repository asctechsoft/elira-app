import 'package:flutter/material.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/ai_tool.dart';
import '../../../values/app_colors.dart';
import 'widgets/ai_run_panel.dart';
import 'widgets/tool_chip.dart';

enum _Category { face, skin, eyesTeeth, makeup, auto }

class _BeautyTool {
  final String label;
  final IconData icon;
  final _Category category;
  const _BeautyTool(this.label, this.icon, this.category);
}

const _categoryLabels = {
  _Category.face: 'Face',
  _Category.skin: 'Skin',
  _Category.eyesTeeth: 'Eyes & Teeth',
  _Category.makeup: 'Makeup',
  _Category.auto: 'Auto',
};

const _categoryIcons = {
  _Category.face: Icons.face_retouching_natural,
  _Category.skin: Icons.spa_outlined,
  _Category.eyesTeeth: Icons.remove_red_eye_outlined,
  _Category.makeup: Icons.brush_outlined,
  _Category.auto: Icons.auto_awesome,
};

// Every one of these routes into the same cloud AI Retouch model below —
// precise, face-aware edits need a real model, not a filter over the whole
// photo, so the choice here is context for that one run rather than a
// separate local algorithm per tool.
const _tools = [
  _BeautyTool('Face Slim', Icons.face_retouching_natural, _Category.face),
  _BeautyTool('Jaw Slim', Icons.expand, _Category.face),
  _BeautyTool('Forehead', Icons.height, _Category.face),
  _BeautyTool('Chin', Icons.vertical_align_bottom, _Category.face),
  _BeautyTool('V-Line', Icons.change_history, _Category.face),
  _BeautyTool('Face Shape', Icons.face, _Category.face),

  _BeautyTool('Smooth Skin', Icons.blur_on, _Category.skin),
  _BeautyTool('AI Skin', Icons.auto_awesome, _Category.skin),
  _BeautyTool('Skin Tone', Icons.palette_outlined, _Category.skin),
  _BeautyTool('Wrinkle Remover', Icons.waves, _Category.skin),
  _BeautyTool('Blemish Remover', Icons.healing, _Category.skin),
  _BeautyTool('Pore Refine', Icons.grain, _Category.skin),
  _BeautyTool('Brighten', Icons.wb_sunny_outlined, _Category.skin),

  _BeautyTool('Eye Enlarge', Icons.remove_red_eye_outlined, _Category.eyesTeeth),
  _BeautyTool('Eye Bag Remover', Icons.visibility_off_outlined, _Category.eyesTeeth),
  _BeautyTool('Dark Circles', Icons.brightness_5_outlined, _Category.eyesTeeth),
  _BeautyTool('Teeth Whiten', Icons.sentiment_satisfied_alt_outlined, _Category.eyesTeeth),
  _BeautyTool('Nose Slim', Icons.compress, _Category.eyesTeeth),
  _BeautyTool('Lip Enhance', Icons.favorite_border, _Category.eyesTeeth),

  _BeautyTool('Lipstick', Icons.brush, _Category.makeup),
  _BeautyTool('Blush', Icons.blur_circular, _Category.makeup),
  _BeautyTool('Eyebrow', Icons.horizontal_rule, _Category.makeup),
  _BeautyTool('Eyeliner', Icons.linear_scale, _Category.makeup),
  _BeautyTool('Eyeshadow', Icons.gradient, _Category.makeup),
  _BeautyTool('Foundation', Icons.layers_outlined, _Category.makeup),

  _BeautyTool('Auto Beauty', Icons.auto_fix_high, _Category.auto),
  _BeautyTool('One-Tap Retouch', Icons.flash_on, _Category.auto),
  _BeautyTool('Portrait Light', Icons.light_mode_outlined, _Category.auto),
];

class RetouchPanel extends StatefulWidget {
  const RetouchPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  State<RetouchPanel> createState() => _RetouchPanelState();
}

class _RetouchPanelState extends State<RetouchPanel> {
  _Category _category = _Category.face;
  late _BeautyTool _selected = _toolsFor(_category).first;

  List<_BeautyTool> _toolsFor(_Category category) =>
      _tools.where((t) => t.category == category).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final toolsInCategory = _toolsFor(_category);
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _Category.values.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final category = _Category.values[i];
                return ToolChip(
                  label: _categoryLabels[category]!,
                  icon: _categoryIcons[category],
                  active: _category == category,
                  onTap: () => setState(() {
                    _category = category;
                    _selected = _toolsFor(category).first;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 82,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: toolsInCategory.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final tool = toolsInCategory[i];
                return _BeautyToolIcon(
                  label: tool.label,
                  icon: tool.icon,
                  active: _selected == tool,
                  onTap: () => setState(() => _selected = tool),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          AiRunPanel(
            ctrl: widget.ctrl,
            tool: AiTools.retouch,
            description:
                '${_selected.label}: applied by the AI Retouch model — precise, '
                'face-aware edits need the cloud, not a filter over the whole photo.',
            bullets: const [
              'Smooth skin, even tone, brighten eyes',
              'Needs a reasonably large photo to work on',
            ],
          ),
        ],
      ),
    );
  }
}

class _BeautyToolIcon extends StatelessWidget {
  const _BeautyToolIcon({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: active ? AppColors.primaryGradient : null,
                color: active ? null : AppColors.cardBg,
                border: active ? null : Border.all(color: AppColors.disabled),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? AppColors.surface : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                height: 1.15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
