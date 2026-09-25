import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/text_layer.dart';
import '../../../models/ui_models/editor_tool.dart';
import '../../../values/app_colors.dart';
import '../../../values/text_fonts.dart';

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
                key: ValueKey(layer.id),
                layer: layer,
                frame: frame,
                selected: editable && layer.id == selectedId,
                interactive: editable,
                onTap: () => ctrl.selectText(layer.id),
                onDrag: (dx, dy) => ctrl.updateText(layer.id, dx: dx, dy: dy),
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

/// Called with the layer's new centre, normalised to the photo frame.
typedef _LayerMove = void Function(double dx, double dy);

class _Layer extends StatefulWidget {
  const _Layer({
    super.key,
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
  final _LayerMove onDrag;
  final VoidCallback onDragEnd;

  @override
  State<_Layer> createState() => _LayerState();
}

class _LayerState extends State<_Layer> {
  // Position is derived from where the finger is relative to where it went
  // down, never by adding a delta to widget.layer: that snapshot only
  // refreshes once per frame, so every extra pointer event in a frame would
  // overwrite the previous one and the layer would fall behind the finger.
  Offset _startPointer = Offset.zero;
  double _startDx = 0;
  double _startDy = 0;

  void _onPanStart(DragStartDetails details) {
    _startPointer = details.globalPosition;
    _startDx = widget.layer.dx;
    _startDy = widget.layer.dy;
    widget.onTap();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final moved = details.globalPosition - _startPointer;
    widget.onDrag(
      _startDx + moved.dx / widget.frame.width,
      _startDy + moved.dy / widget.frame.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final layer = widget.layer;
    final frame = widget.frame;
    final fontSize = layer.size * frame.height;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: widget.selected
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
        ignoring: !widget.interactive,
        child: GestureDetector(
          behavior: HitTestBehavior.deferToChild,
          // Start from the touch-down point so the first slop pixels are not
          // swallowed, which reads as a hitch at the start of every drag.
          dragStartBehavior: DragStartBehavior.down,
          onTap: widget.onTap,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: (_) => widget.onDragEnd(),
          child: RepaintBoundary(child: Center(child: content)),
        ),
      ),
    );
  }
}
