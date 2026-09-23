import 'package:get/get.dart';
import '../controller/onboarding_controller.dart';
import '../controller/home_controller.dart';
import '../controller/photo_picker_controller.dart';
import '../controller/editor_controller.dart';
import '../controller/export_controller.dart';
import '../controller/ai_studio_controller.dart';
import '../controller/create_controller.dart';
import '../controller/profile_controller.dart';
import '../presentation/screen_splash/splash_screen.dart';
import '../presentation/screen_onboarding/onboarding_screen.dart';
import '../presentation/screen_main/main_shell.dart';
import '../presentation/screen_photo_picker/photo_picker_screen.dart';
import '../presentation/screen_editor/editor_screen.dart';
import '../presentation/screen_export/export_screen.dart';
import 'route_name.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: RouteName.splash,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: RouteName.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder<void>(() { Get.put(OnboardingController()); }),
    ),
    GetPage(
      name: RouteName.main,
      page: () => const MainShell(),
      binding: BindingsBuilder<void>(() {
        Get.put(HomeController());
        Get.put(AiStudioController());
        Get.put(CreateController());
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: RouteName.photoPicker,
      page: () => const PhotoPickerScreen(),
      binding: BindingsBuilder<void>(() { Get.put(PhotoPickerController()); }),
    ),
    GetPage(
      name: RouteName.editor,
      page: () => const EditorScreen(),
      binding: BindingsBuilder<void>(() { Get.put(EditorController()); }),
    ),
    GetPage(
      name: RouteName.export,
      page: () => const ExportScreen(),
      binding: BindingsBuilder<void>(() { Get.put(ExportController()); }),
    ),
  ];
}
