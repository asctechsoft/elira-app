import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/editor_controller.dart';
import '../../common_components/tool_slider.dart';

class AdjustPanel extends StatelessWidget {
  final EditorController ctrl;

  const AdjustPanel({super.key, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() => ToolSlider(
          label: 'Brightness',
          value: ctrl.brightness.value,
          min: -100,
          max: 100,
          onChanged: (v) => ctrl.brightness.value = v,
          onReset: () => ctrl.brightness.value = 0,
          onAuto: () {},
        ));
  }
}
