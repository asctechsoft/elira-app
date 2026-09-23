import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/editor_controller.dart';
import '../../models/ui_models/editor_tool.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import 'tools/adjust_panel.dart';
import 'tools/filters_panel.dart';
import 'tools/crop_panel.dart';
import 'tools/retouch_panel.dart';
import 'tools/remove_panel.dart';
import 'tools/background_panel.dart';
import 'tools/effects_panel.dart';
import 'tools/text_panel.dart';
import 'tools/ai_panel.dart';

class EditorScreen extends StatelessWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<EditorController>();
    return Scaffold(
      backgroundColor: const Color(0xFF1A1D2E),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            _EditorTopBar(ctrl: ctrl),

            // Image preview area
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Main image
                  Obx(() => ctrl.imagePath.value.isNotEmpty
                      ? Image.file(File(ctrl.imagePath.value), fit: BoxFit.contain)
                      : Container(
                          margin: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, color: Colors.white30, size: 64),
                          ),
                        )),
                  // AI badge
                  const Positioned(
                    bottom: 20,
                    left: 30,
                    child: _AiBadge(label: 'AI Enhanced'),
                  ),
                ],
              ),
            ),

            // Version strip (multiple edits)
            Container(
              height: 72,
              color: const Color(0xFF252836),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  ...List.generate(
                    4,
                    (i) => Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(8),
                        border: i == 0 ? Border.all(color: AppColors.primary, width: 2) : null,
                      ),
                    ),
                  ),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.add, color: Colors.white38),
                  ),
                ],
              ),
            ),

            // Tool tabs
            Obx(() => _EditorToolTabs(
                  activeTool: ctrl.activeTool.value,
                  onToolChanged: ctrl.setTool,
                )),

            // Tool panel
            Obx(() => _buildPanel(ctrl.activeTool.value, ctrl)),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(EditorTool tool, EditorController ctrl) {
    return switch (tool) {
      EditorTool.adjust => AdjustPanel(ctrl: ctrl),
      EditorTool.filters => const FiltersPanel(),
      EditorTool.crop => const CropPanel(),
      EditorTool.retouch => const RetouchPanel(),
      EditorTool.remove => const RemovePanel(),
      EditorTool.background => const BackgroundPanel(),
      EditorTool.effects => const EffectsPanel(),
      EditorTool.text => const TextPanel(),
      EditorTool.ai => const AiPanel(),
    };
  }
}

class _EditorTopBar extends StatelessWidget {
  final EditorController ctrl;

  const _EditorTopBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Portrait Edit', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(width: 6),
                    Icon(Icons.edit_outlined, color: Colors.white54, size: 14),
                  ],
                ),
                const Text('Saved 2 min ago', style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          // Undo
          Obx(() => IconButton(
                onPressed: ctrl.canUndo.value ? ctrl.undo : null,
                icon: Icon(Icons.undo, color: ctrl.canUndo.value ? Colors.white : Colors.white30),
              )),
          // Redo
          Obx(() => IconButton(
                onPressed: ctrl.canRedo.value ? ctrl.redo : null,
                icon: Icon(Icons.redo, color: ctrl.canRedo.value ? Colors.white : Colors.white30),
              )),
          // Compare
          Column(
            children: const [
              Icon(Icons.compare, color: Colors.white70, size: 20),
              Text('Compare', style: TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),
          const SizedBox(width: 12),
          // Export button
          GestureDetector(
            onTap: () => Get.toNamed(RouteName.export),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.upload_outlined, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Export', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorToolTabs extends StatelessWidget {
  final EditorTool activeTool;
  final ValueChanged<EditorTool> onToolChanged;

  const _EditorToolTabs({required this.activeTool, required this.onToolChanged});

  static const _tools = [
    (EditorTool.adjust, Icons.wb_sunny_outlined, 'Adjust'),
    (EditorTool.filters, Icons.lens_blur, 'Filters'),
    (EditorTool.crop, Icons.crop, 'Crop'),
    (EditorTool.retouch, Icons.face_retouching_natural, 'Retouch'),
    (EditorTool.remove, Icons.cleaning_services, 'Remove'),
    (EditorTool.background, Icons.image_outlined, 'BG'),
    (EditorTool.effects, Icons.auto_awesome_outlined, 'Effects'),
    (EditorTool.text, Icons.text_fields, 'Text'),
    (EditorTool.ai, Icons.auto_awesome, 'AI'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: const Color(0xFF252836),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: _tools
            .map((t) => _ToolTab(
                  tool: t.$1,
                  icon: t.$2,
                  label: t.$3,
                  active: activeTool == t.$1,
                  onTap: () => onToolChanged(t.$1),
                ))
            .toList(),
      ),
    );
  }
}

class _ToolTab extends StatelessWidget {
  final EditorTool tool;
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToolTab({required this.tool, required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? AppColors.primary : Colors.white54, size: 22),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: active ? AppColors.primary : Colors.white38, fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _AiBadge extends StatelessWidget {
  final String label;

  const _AiBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
