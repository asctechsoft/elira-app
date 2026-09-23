import 'package:get/get.dart';

class ExportController extends GetxController {
  final isJpeg = true.obs;
  final quality = 90.0.obs;
  final addWatermark = false.obs;
  final isExporting = false.obs;

  void toggleFormat() => isJpeg.value = !isJpeg.value;
  void setQuality(double v) => quality.value = v;
  void toggleWatermark(bool v) => addWatermark.value = v;

  Future<void> exportPhoto() async {
    isExporting.value = true;
    await Future.delayed(const Duration(seconds: 2));
    isExporting.value = false;
  }
}
