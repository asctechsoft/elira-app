import 'package:get/get.dart';

import '../data/auth/social_provider.dart';
import '../values/route_name.dart';
import 'auth_controller.dart';

class LoginController extends GetxController {
  AuthController get auth => AuthController.to;

  Future<void> signInWithSocial(SocialAuthProvider provider) async {
    auth.clearError();
    final ok = await auth.signInWithSocial(provider);
    if (ok) Get.offAllNamed(RouteName.main);
  }
}
