import 'package:get/get.dart';
import '../controller/onboarding_controller.dart';
import '../data/ai/ai_service.dart';
import '../data/presets/preset_repository.dart';
import '../data/projects/project_repository.dart';
import '../data/projects/project_sync.dart';
import '../services/project_draft_service.dart';
import '../controller/home_controller.dart';
import '../controller/photo_picker_controller.dart';
import '../controller/editor_controller.dart';
import '../controller/export_controller.dart';
import '../controller/ai_studio_controller.dart';
import '../controller/create_controller.dart';
import '../controller/profile_controller.dart';
import '../controller/splash_controller.dart';
import '../controller/login_controller.dart';
import '../controller/forgot_password_controller.dart';
import '../presentation/screen_splash/splash_screen.dart';
import '../presentation/screen_onboarding/onboarding_screen.dart';
import '../presentation/screen_auth/login_screen.dart';
import '../presentation/screen_auth/forgot_password_screen.dart';
import '../presentation/screen_main/main_shell.dart';
import '../presentation/screen_photo_picker/photo_picker_screen.dart';
import '../presentation/screen_projects/project_list_screen.dart';
import '../presentation/screen_templates/template_list_screen.dart';
import '../presentation/screen_editor/editor_screen.dart';
import '../presentation/screen_export/export_screen.dart';
import 'route_guards.dart';
import 'route_name.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: RouteName.splash,
      page: () => const SplashScreen(),
      binding: BindingsBuilder<void>(() { Get.put(SplashController()); }),
    ),
    GetPage(
      name: RouteName.onboarding,
      page: () => const OnboardingScreen(),
      binding: BindingsBuilder<void>(() { Get.put(OnboardingController()); }),
    ),
    GetPage(
      name: RouteName.login,
      page: () => const LoginScreen(),
      binding: BindingsBuilder<void>(() { Get.put(LoginController()); }),
      middlewares: [GuestOnlyMiddleware()],
    ),
    // No guard: a signed-in user changing their password is legitimate.
    GetPage(
      name: RouteName.forgotPassword,
      page: () => const ForgotPasswordScreen(),
      binding: BindingsBuilder<void>(() { Get.put(ForgotPasswordController()); }),
    ),
    GetPage(
      name: RouteName.main,
      page: () => const MainShell(),
      // MainShell renders all four tabs in an IndexedStack, so these are built
      // immediately either way; lazyPut still avoids constructing them when a
      // guard redirects the route away.
      binding: BindingsBuilder<void>(() {
        Get.lazyPut(() => HomeController(projects: Get.find<ProjectRepository>()));
        Get.lazyPut(() => AiStudioController(service: Get.find<AiService>()));
        Get.lazyPut(() => CreateController());
        Get.lazyPut(() => ProfileController());
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: RouteName.photoPicker,
      page: () => const PhotoPickerScreen(),
      binding: BindingsBuilder<void>(() {
        Get.put(PhotoPickerController(
          drafts: ProjectDraftService(repository: Get.find<ProjectRepository>()),
        ));
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: RouteName.editor,
      page: () => const EditorScreen(),
      binding: BindingsBuilder<void>(() {
        Get.put(EditorController(
          projects: Get.find<ProjectRepository>(),
          presets: Get.find<PresetRepository>(),
          sync: Get.find<BackgroundProjectSync>(),
        ));
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: RouteName.templates,
      page: () => const TemplateListScreen(),
      binding: BindingsBuilder<void>(() { Get.lazyPut(() => CreateController()); }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: RouteName.projects,
      page: () => const ProjectListScreen(),
      binding: BindingsBuilder<void>(() {
        Get.lazyPut(() => HomeController(projects: Get.find<ProjectRepository>()));
      }),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: RouteName.export,
      page: () => const ExportScreen(),
      binding: BindingsBuilder<void>(() { Get.put(ExportController()); }),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
