import 'package:get/get.dart';

class AiStudioController extends GetxController {
  final credits = 120.obs;
  final isProcessing = false.obs;

  Future<void> runTool(String toolName) async {
    isProcessing.value = true;
    await Future.delayed(const Duration(seconds: 3));
    isProcessing.value = false;
  }
}
