import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/text_layer.dart';
import '../../../models/ui_models/editor_tool.dart';
import '../../../values/app_colors.dart';
import 'text_fonts.dart';

/// Draws the text layers over the canvas and lets them be dragged.
///
/// It sits above the image's `ColorFiltered`, so a filter or a brightness
/// slider never tints the caption — and, because text is not part of any
/// render stage, adding one costs no image processing at all.
class TextOverlay extends StatelessWidget {
  const TextOverlay({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final layers = ctrl.texts.toList();
    final selectedId = ctrl.selectedTextId.value;
    final editable = ctrl.activeTool.value == EditorTool.text;
    final aspect = ctrl.displayAspect;

    if (layers.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = fittedImageRect(constraints.biggest, aspect);
        if (frame.isEmpty) return const SizedBox.shrink();

        return Stack(
          children: [
            for (final layer in layers)
              _Layer(
                layer: layer,
                frame: frame,
                selected: editable && layer.id == selectedId,
                interactive: editable,
                onTap: () => ctrl.selectText(layer.id),
                onDrag: (delta) {
                  ctrl.updateText(
                    layer.id,
                    dx: layer.dx + delta.dx / frame.width,
                    dy: layer.dy + delta.dy / frame.height,
                  );
                },
                onDragEnd: () => ctrl.commitText('Text'),
              ),
          ],
        );
      },
    );
  }
}

/// The rect a `BoxFit.contain` image occupies inside [size]. Shared by the
/// text and crop overlays so they agree on where the photo actually is.
Rect fittedImageRect(Size size, double aspect) {
  if (size.width <= 0 || size.height <= 0 || aspect <= 0) return Rect.zero;
  var width = size.width;
  var height = width / aspect;
  if (height > size.height) {
    height = size.height;
    width = height * aspect;
  }
  return Rect.fromLTWH(
    (size.width - width) / 2,
    (size.height - height) / 2,
    width,
    height,
  );
}

class _Layer extends StatelessWidget {
  const _Layer({
    required this.layer,
    required this.frame,
    required this.selected,
    required this.interactive,
    required this.onTap,
    required this.onDrag,
    required this.onDragEnd,
  });

  final TextLayer layer;
  final Rect frame;
  final bool selected;
  final bool interactive;
  final VoidCallback onTap;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final fontSize = layer.size * frame.height;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: selected
          ? BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Text(
        layer.text,
        textAlign: textAlignOf(layer.align),
        style: TextFonts.byId(layer.fontId)
            .style(fontSize: fontSize, color: Color(layer.color)),
      ),
    );

    // The layer is anchored by its centre, so scaling the text does not make
    // it drift across the photo.
    return Positioned(
      left: frame.left + layer.dx * frame.width - frame.width / 2,
      top: frame.top + layer.dy * frame.height - fontSize * 2,
      width: frame.width,
      height: fontSize * 4,
      child: IgnorePointer(
        ignoring: !interactive,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          onTap: onTap,
          onPanStart: (_) => onTap(),
          onPanUpdate: (details) => onDrag(details.delta),
          onPanEnd: (_) => onDragEnd(),
          child: Center(child: content),
        ),
      ),
    );
  }
}
