import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../controller/auth_controller.dart';
import 'route_name.dart';

/// Splash owns the async cold-start decision; these guards catch every other
/// way into a protected route (deep link, hot reload, a stale route) with a
/// cheap synchronous check. Returning null means "allow" — returning the same
/// route is an infinite redirect loop.
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) return null;
    return AuthController.to.isSignedIn
        ? null
        : const RouteSettings(name: RouteName.onboarding);
  }
}

class GuestOnlyMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    if (!Get.isRegistered<AuthController>()) return null;
    final auth = AuthController.to;
    // An anonymous session is still allowed in: signup is how a guest upgrades.
    return auth.isSignedIn && !auth.isGuest
        ? const RouteSettings(name: RouteName.main)
        : null;
  }
}
