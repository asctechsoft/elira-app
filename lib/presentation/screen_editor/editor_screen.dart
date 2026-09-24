import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/editor_controller.dart';
import '../../models/ui_models/editor_tool.dart';
import '../../services/image_pipeline.dart';
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
import 'widgets/crop_overlay.dart';
import 'widgets/text_overlay.dart';

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
                  _Canvas(ctrl: ctrl),
                  // Above the canvas's ColorFiltered, so a filter never tints
                  // the caption.
                  Positioned.fill(child: TextOverlay(ctrl: ctrl)),
                  Positioned.fill(child: CropOverlay(ctrl: ctrl)),
                  Obx(() => ctrl.isRendering.value
                      ? const Positioned(
                          top: 16,
                          right: 20,
                          child: _RenderingBadge(),
                        )
                      : const SizedBox.shrink()),
                  Obx(() {
                    final message = ctrl.errorMessage.value;
                    if (message == null) return const SizedBox.shrink();
                    return Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: _ErrorBar(message: message, onDismiss: ctrl.clearError),
                    );
                  }),
                ],
              ),
            ),

            // Version strip, bound to the real undo history
            _VersionStrip(ctrl: ctrl),

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
      EditorTool.filters => FiltersPanel(ctrl: ctrl),
      EditorTool.crop => CropPanel(ctrl: ctrl),
      EditorTool.retouch => RetouchPanel(ctrl: ctrl),
      EditorTool.remove => RemovePanel(ctrl: ctrl),
      EditorTool.background => BackgroundPanel(ctrl: ctrl),
      EditorTool.effects => EffectsPanel(ctrl: ctrl),
      EditorTool.text => TextPanel(ctrl: ctrl),
      EditorTool.ai => AiPanel(ctrl: ctrl),
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
            child: Obx(() {
              final project = ctrl.project.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          ctrl.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined, color: Colors.white54, size: 14),
                    ],
                  ),
                  Text(
                    project?.resolutionLabel ?? '',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              );
            }),
          ),
          // Undo
          Obx(() => IconButton(
                onPressed: ctrl.canUndo.value ? () => ctrl.undo() : null,
                icon: Icon(Icons.undo, color: ctrl.canUndo.value ? Colors.white : Colors.white30),
              )),
          // Redo
          Obx(() => IconButton(
                onPressed: ctrl.canRedo.value ? () => ctrl.redo() : null,
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



class _Canvas extends StatelessWidget {
  const _Canvas({required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) => Obx(_buildCanvas);

  Widget _buildCanvas() {
    if (ctrl.isLoading.value) {
      return const Center(child: CircularProgressIndicator(color: Colors.white54));
    }
    final bytes = ctrl.previewBase.value;
    if (bytes != null) {
      // gaplessPlayback keeps the old frame on screen while a new sharpness
      // base decodes, so the canvas does not flash.
      final image = Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
      final matrix = ctrl.colorMatrix;
      if (ImagePipeline.isIdentityMatrix(matrix)) return image;
      // Colour edits are applied here on the GPU every frame, which is what
      // lets the canvas keep up with a slider or a burst of version taps.
      return ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: image);
    }
    final path = ctrl.imagePath.value;
    if (path.isNotEmpty) {
      return Image.file(File(path), fit: BoxFit.contain);
    }
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white30, size: 64),
      ),
    );
  }
}

class _RenderingBadge extends StatelessWidget {
  const _RenderingBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: Colors.white),
          ),
          SizedBox(width: 6),
          Text('Rendering', style: TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ErrorBar extends StatelessWidget {
  const _ErrorBar({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(Icons.close, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

/// Version strip. Entry 0 is the untouched original; each following entry is a
/// committed operation. Entries past the cursor are the redo tail and are shown
/// dimmed rather than hidden, so an undo does not make work appear to vanish.
class _VersionStrip extends StatelessWidget {
  const _VersionStrip({required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) => Obx(_buildStrip);

  Widget _buildStrip() {
    final history = ctrl.history;
    final cursor = ctrl.historyCursor.value;

    return Container(
      height: 72,
      color: const Color(0xFF252836),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: history.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isOriginal = i == 0;
          final op = isOriginal ? null : history[i - 1];
          return _VersionChip(
            label: isOriginal ? 'Original' : op!.label,
            thumbnail: op?.thumbnail,
            selected: i == cursor,
            dimmed: i > cursor,
            onTap: () => ctrl.jumpTo(i),
          );
        },
      ),
    );
  }
}

class _VersionChip extends StatelessWidget {
  const _VersionChip({
    required this.label,
    required this.thumbnail,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  final String label;
  final Uint8List? thumbnail;
  final bool selected;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: dimmed ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(8),
                border: selected ? Border.all(color: AppColors.primary, width: 2) : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnail == null
                  ? const Icon(Icons.image_outlined, color: Colors.white38, size: 18)
                  : Image.memory(thumbnail!, fit: BoxFit.cover, gaplessPlayback: true),
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: 52,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: selected ? AppColors.primary : Colors.white38,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
