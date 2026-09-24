import 'package:flutter/material.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/ai_tool.dart';
import 'widgets/ai_run_panel.dart';

class RetouchPanel extends StatelessWidget {
  const RetouchPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return AiRunPanel(
      ctrl: ctrl,
      tool: AiTools.retouch,
      description:
          'Skin, eyes and teeth adjusted only where they actually are in the '
          'frame — which needs face detection, so it runs on the cloud model '
          'rather than as a blur over the whole photo.',
      bullets: [
        'Smooth skin, even tone, brighten eyes',
        'Needs a reasonably large photo to work on',
      ],
    );
  }
}
