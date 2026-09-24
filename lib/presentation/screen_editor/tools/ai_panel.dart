import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/ai_studio_controller.dart';
import '../../../controller/editor_controller.dart';
import '../../../models/data_models/ai_tool.dart';
import '../../../values/app_colors.dart';
import 'widgets/ai_run_panel.dart';

/// The AI tools available on the photo that is open. Picking one opens the
/// same run panel the dedicated tabs use, so cost, gating and Apply/Discard
/// behave identically wherever a tool is started from.
class AiPanel extends StatefulWidget {
  const AiPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  State<AiPanel> createState() => _AiPanelState();
}

class _AiPanelState extends State<AiPanel> {
  static const _tools = [
    (AiTools.enhance, Icons.auto_fix_high, AppColors.actionEnhance),
    (AiTools.retouch, Icons.face_retouching_natural, AppColors.actionRetouch),
    (AiTools.removeBackground, Icons.cleaning_services, AppColors.actionRemove),
    (AiTools.expand, Icons.open_in_full, AppColors.actionFilters),
    (AiTools.relight, Icons.brightness_high, AppColors.actionBackground),
    (AiTools.restore, Icons.restore, AppColors.actionAiMagic),
  ];

  AiTool _selected = AiTools.enhance;

  AiStudioController? get _ai =>
      Get.isRegistered<AiStudioController>() ? Get.find<AiStudioController>() : null;

  @override
  Widget build(BuildContext context) {
    final ai = _ai;
    return Container(
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              itemCount: _tools.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final (tool, icon, colour) = _tools[i];
                final active = tool.id == _selected.id;
                return GestureDetector(
                  // Switching tools mid-run would leave an orphaned job, so it
                  // is blocked while one is in flight.
                  onTap: (ai?.isProcessing ?? false)
                      ? null
                      : () => setState(() => _selected = tool),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colour,
                          borderRadius: BorderRadius.circular(14),
                          border: active
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                        ),
                        child: Icon(icon, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: active ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          AiRunPanel(
            ctrl: widget.ctrl,
            tool: _selected,
            description: _selected.tagline,
            bullets: const [
              'Each run costs credits from your balance',
              'Photos are sent over a short-lived signed link',
            ],
          ),
        ],
      ),
    );
  }
}
