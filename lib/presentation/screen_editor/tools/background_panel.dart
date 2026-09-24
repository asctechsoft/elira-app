import 'package:flutter/material.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/ai_tool.dart';
import 'widgets/ai_run_panel.dart';

class BackgroundPanel extends StatelessWidget {
  const BackgroundPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return AiRunPanel(
      ctrl: ctrl,
      tool: AiTools.removeBackground,
      description:
          'Cuts the subject out first. Choosing a colour, gradient or photo to '
          'put behind it comes after that, because until the subject is '
          'separated there is no background to replace.',
      bullets: [
        'Edge refinement for hair and soft outlines',
        'Replacing the background is the next step, not this one',
      ],
    );
  }
}
