import 'package:flutter/material.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/ai_tool.dart';
import 'widgets/ai_run_panel.dart';

class RemovePanel extends StatelessWidget {
  const RemovePanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return AiRunPanel(
      ctrl: ctrl,
      tool: AiTools.removeObject,
      description:
          'Takes out what you do not want and fills in what was behind it.',
      bullets: [
        'Runs on the cloud model, not on your phone',
        'The original photo is never overwritten',
      ],
    );
  }
}
