import 'package:get/get.dart';

class HomeController extends GetxController {
  final currentTabIndex = 0.obs;

  void changeTab(int index) => currentTabIndex.value = index;
}
