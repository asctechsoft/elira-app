import 'package:get/get.dart';
import '../models/ui_models/editor_tool.dart';

class EditorController extends GetxController {
  final imagePath = ''.obs;
  final activeTool = EditorTool.adjust.obs;
  final canUndo = false.obs;
  final canRedo = false.obs;
  final isSaved = true.obs;

  // Adjust values
  final brightness = 0.0.obs;
  final contrast = 0.0.obs;
  final saturation = 0.0.obs;
  final sharpness = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is String && arg.isNotEmpty) imagePath.value = arg;
  }

  void setImage(String path) => imagePath.value = path;

  void setTool(EditorTool tool) => activeTool.value = tool;

  void undo() {}
  void redo() {}
}
