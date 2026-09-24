import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/text_layer.dart';
import '../../../values/app_colors.dart';
import '../../common_components/tool_slider.dart';
import '../widgets/text_fonts.dart';
import 'widgets/tool_chip.dart';

/// Add Text, then font / colour / alignment / size for whichever layer is
/// selected. Nothing here is enabled until a layer exists, so the controls
/// never look live while they have nothing to act on.
class TextPanel extends StatelessWidget {
  const TextPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      child: Obx(() => _build(context)),
    );
  }

  Widget _build(BuildContext context) {
    final layer = ctrl.selectedText;
    final count = ctrl.texts.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _edit(context, null),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: AppColors.surface, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Text',
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
              if (layer != null) ...[
                const SizedBox(width: 10),
                _RoundAction(
                  icon: Icons.edit_outlined,
                  onTap: () => _edit(context, layer),
                ),
                const SizedBox(width: 8),
                _RoundAction(
                  icon: Icons.delete_outline,
                  danger: true,
                  onTap: () => ctrl.removeText(layer.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (layer == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              count == 0
                  ? 'No text yet. Add one, then drag it on the photo.'
                  : 'Tap a text on the photo to edit it.',
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          )
        else ...[
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: TextFonts.all.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final font = TextFonts.all[i];
                final active = font.id == layer.fontId;
                return GestureDetector(
                  onTap: () {
                    ctrl.updateText(layer.id, fontId: font.id);
                    ctrl.commitText('Text');
                  },
                  child: Container(
                    width: 46,
                    decoration: BoxDecoration(
                      color: active ? null : AppColors.cardBg,
                      gradient: active ? AppColors.primaryGradient : null,
                      borderRadius: BorderRadius.circular(11),
                      border: active ? null : Border.all(color: AppColors.disabled),
                    ),
                    child: Center(
                      child: Text(
                        font.sample,
                        style: font.style(
                          fontSize: 17,
                          color: active ? AppColors.surface : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: TextFonts.colors.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final value = TextFonts.colors[i];
                final active = value == layer.color;
                return GestureDetector(
                  onTap: () {
                    ctrl.updateText(layer.id, color: value);
                    ctrl.commitText('Text');
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(value),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? AppColors.primary : AppColors.disabled,
                        width: active ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                for (final align in TextLayerAlign.values) ...[
                  ToolChip(
                    label: _alignLabel(align),
                    icon: _alignIcon(align),
                    active: layer.align == align,
                    onTap: () {
                      ctrl.updateText(layer.id, align: align);
                      ctrl.commitText('Text');
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          ToolSlider(
            compact: true,
            label: 'Size',
            min: 2,
            max: 40,
            value: layer.size * 100,
            onChanged: (v) => ctrl.updateText(layer.id, size: v / 100),
            onChangeEnd: (_) => ctrl.commitText('Text'),
          ),
        ],
      ],
    );
  }

  static String _alignLabel(TextLayerAlign align) => switch (align) {
        TextLayerAlign.left => 'Left',
        TextLayerAlign.center => 'Center',
        TextLayerAlign.right => 'Right',
      };

  static IconData _alignIcon(TextLayerAlign align) => switch (align) {
        TextLayerAlign.left => Icons.format_align_left,
        TextLayerAlign.center => Icons.format_align_center,
        TextLayerAlign.right => Icons.format_align_right,
      };

  Future<void> _edit(BuildContext context, TextLayer? layer) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _TextDialog(initial: layer?.text ?? ''),
    );
    if (result == null) return;

    if (layer == null) {
      if (result.trim().isEmpty) return;
      await ctrl.addText(result);
    } else {
      ctrl.updateText(layer.id, text: result);
      await ctrl.commitText('Text');
    }
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.disabled),
        ),
        child: Icon(icon,
            size: 19, color: danger ? AppColors.error : AppColors.textPrimary),
      ),
    );
  }
}

class _TextDialog extends StatefulWidget {
  const _TextDialog({required this.initial});

  final String initial;

  @override
  State<_TextDialog> createState() => _TextDialogState();
}

class _TextDialogState extends State<_TextDialog> {
  late final TextEditingController _field =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(widget.initial.isEmpty ? 'Add text' : 'Edit text'),
      content: TextField(
        controller: _field,
        autofocus: true,
        maxLines: 3,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(hintText: 'Type something'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_field.text),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
