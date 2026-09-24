import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../values/app_colors.dart';
import 'text_overlay.dart' show fittedImageRect;

/// The draggable crop box. It is laid out against the *displayed* image rect,
/// not the whole canvas, so the handles stay on the photo's edges however the
/// frame is letterboxed.
class CropOverlay extends StatelessWidget {
  const CropOverlay({super.key, required this.ctrl});

  final EditorController ctrl;

  /// Touch target around each corner.
  static const double _handle = 32;

  /// Smallest box we let someone drag to, as a fraction of the frame.
  static const double _minSize = 0.08;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    if (!ctrl.isCropping.value) return const SizedBox.shrink();

    final geometry = ctrl.geometry.value;
    final aspect = ctrl.frameAspect;
    final ratio = ctrl.cropRatio.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final frame = fittedImageRect(constraints.biggest, aspect);
        if (frame.width <= 0 || frame.height <= 0) {
          return const SizedBox.shrink();
        }

        final box = Rect.fromLTRB(
          frame.left + geometry.left * frame.width,
          frame.top + geometry.top * frame.height,
          frame.left + geometry.right * frame.width,
          frame.top + geometry.bottom * frame.height,
        );

        void update(Rect next) {
          ctrl.setCropRect(
            left: (next.left - frame.left) / frame.width,
            top: (next.top - frame.top) / frame.height,
            right: (next.right - frame.left) / frame.width,
            bottom: (next.bottom - frame.top) / frame.height,
          );
        }

        return Stack(
          children: [
            // Dim everything outside the box so the crop reads at a glance.
            Positioned.fromRect(
              rect: frame,
              child: CustomPaint(
                painter: _ScrimPainter(box.shift(-frame.topLeft)),
              ),
            ),
            Positioned.fromRect(
              rect: box,
              child: IgnorePointer(child: CustomPaint(painter: _GridPainter())),
            ),
            // Whole-box drag.
            Positioned.fromRect(
              rect: box,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanUpdate: (details) {
                  var next = box.shift(details.delta);
                  final dx = next.left < frame.left
                      ? frame.left - next.left
                      : next.right > frame.right
                          ? frame.right - next.right
                          : 0.0;
                  final dy = next.top < frame.top
                      ? frame.top - next.top
                      : next.bottom > frame.bottom
                          ? frame.bottom - next.bottom
                          : 0.0;
                  next = next.shift(Offset(dx, dy));
                  update(next);
                },
              ),
            ),
            for (final corner in _Corner.values)
              _CornerHandle(
                corner: corner,
                box: box,
                size: _handle,
                onDrag: (delta) => update(
                  _resize(
                    box: box,
                    frame: frame,
                    corner: corner,
                    delta: delta,
                    ratio: ratio,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Moves one corner, keeping the box inside [frame] and — when a preset is
  /// locked — keeping its aspect. The locked case drives height from width so
  /// a diagonal drag cannot slowly skew the ratio.
  static Rect _resize({
    required Rect box,
    required Rect frame,
    required _Corner corner,
    required Offset delta,
    required double? ratio,
  }) {
    final minW = frame.width * _minSize;
    final minH = frame.height * _minSize;

    var left = box.left;
    var top = box.top;
    var right = box.right;
    var bottom = box.bottom;

    switch (corner) {
      case _Corner.topLeft:
        left = (box.left + delta.dx).clamp(frame.left, box.right - minW);
        top = (box.top + delta.dy).clamp(frame.top, box.bottom - minH);
      case _Corner.topRight:
        right = (box.right + delta.dx).clamp(box.left + minW, frame.right);
        top = (box.top + delta.dy).clamp(frame.top, box.bottom - minH);
      case _Corner.bottomLeft:
        left = (box.left + delta.dx).clamp(frame.left, box.right - minW);
        bottom = (box.bottom + delta.dy).clamp(box.top + minH, frame.bottom);
      case _Corner.bottomRight:
        right = (box.right + delta.dx).clamp(box.left + minW, frame.right);
        bottom = (box.bottom + delta.dy).clamp(box.top + minH, frame.bottom);
    }

    final next = Rect.fromLTRB(left, top, right, bottom);
    if (ratio == null) return next;

    // [frame] is the image drawn to scale, so the box's pixel aspect already
    // *is* the crop's final aspect — no conversion through image dimensions.
    // Height follows width, so a diagonal drag cannot slowly skew the preset.
    var width = next.width;
    var height = width / ratio;
    if (height < minH) {
      height = minH;
      width = height * ratio;
    }

    final anchorsTop = corner == _Corner.topLeft || corner == _Corner.topRight;
    final anchorsLeft = corner == _Corner.topLeft || corner == _Corner.bottomLeft;

    // The corner opposite the one being dragged stays put, so the box grows
    // only into the space actually available on that side.
    final availableH = anchorsTop ? next.bottom - frame.top : frame.bottom - next.top;
    final availableW = anchorsLeft ? next.right - frame.left : frame.right - next.left;
    if (height > availableH) {
      height = availableH;
      width = height * ratio;
    }
    if (width > availableW) {
      width = availableW;
      height = width / ratio;
    }

    final l = anchorsLeft ? next.right - width : next.left;
    final t = anchorsTop ? next.bottom - height : next.top;
    return Rect.fromLTRB(l, t, l + width, t + height);
  }
}

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.corner,
    required this.box,
    required this.size,
    required this.onDrag,
  });

  final _Corner corner;
  final Rect box;
  final double size;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) {
    final centre = switch (corner) {
      _Corner.topLeft => box.topLeft,
      _Corner.topRight => box.topRight,
      _Corner.bottomLeft => box.bottomLeft,
      _Corner.bottomRight => box.bottomRight,
    };

    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter(this.hole);

  final Rect hole;

  @override
  void paint(Canvas canvas, Size size) {
    final scrim = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawRect(Offset.zero & size, scrim);
    canvas.drawRect(hole, Paint()..blendMode = BlendMode.clear);
    canvas.restore();

    canvas.drawRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_ScrimPainter old) => old.hole != hole;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = size.width * i / 3;
      final dy = size.height * i / 3;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), paint);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
