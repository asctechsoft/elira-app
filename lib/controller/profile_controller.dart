import 'package:get/get.dart';

import '../data/auth/auth_user.dart';
import '../models/data_models/app_user.dart';
import '../values/app_strings.dart';
import '../values/route_name.dart';
import 'auth_controller.dart';

class ProfileController extends GetxController {
  AuthController get _auth => AuthController.to;

  final isSaving = false.obs;

  // Every getter dereferences an observable so reading it inside an Obx
  // actually registers the dependency. A getter that never touches `.value`
  // makes GetX throw "Improper use of a GetX" at runtime, not compile time.
  AuthUser? get authUser => _auth.firebaseUser.value;
  AppUser? get profile => _auth.profile.value;

  bool get isGuest => _auth.firebaseUser.value?.isAnonymous ?? false;
  bool get isPro => _auth.profile.value?.subscription.isActive ?? false;
  bool get isProfileLoading => _auth.profile.value == null && _auth.firebaseUser.value != null;

  String get displayName {
    final name = authUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return isGuest ? AppStrings.guestName : AppStrings.unnamedUser;
  }

  String get email => authUser?.email ?? '';

  String? get photoUrl => authUser?.photoUrl;

  String get badge {
    if (isGuest) return AppStrings.guestBadge;
    return isPro ? AppStrings.proBadge : AppStrings.freeBadge;
  }

  /// Avatar fallback so phase 1 needs no Firebase Storage.
  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  int get projectCount => profile?.stats.projects ?? 0;
  int get favoriteCount => profile?.stats.favorites ?? 0;
  int get aiCredits => profile?.credits.balance ?? 0;

  // Library counts have no backing data until the persistence phase lands.
  // Rendering real zeros beats inventing Firestore fields that nothing writes.
  int get draftCount => profile?.stats.projects ?? 0;
  int get downloadCount => profile?.stats.exports ?? 0;
  int get presetCount => profile?.stats.presets ?? 0;

  /// Named reloadProfile rather than refresh: GetxController already defines
  /// refresh() and shadowing it silently breaks Obx rebuilds.
  Future<void> reloadProfile() => _auth.refreshProfile();

  Future<bool> saveDisplayName(String name) async {
    isSaving.value = true;
    try {
      return await _auth.updateDisplayName(name);
    } finally {
      isSaving.value = false;
    }
  }

  void goToSignup() => Get.toNamed(RouteName.signup);

  Future<void> signOut() async {
    await _auth.signOut();
    // offAllNamed tears the stack down so Back cannot return to a signed-in
    // screen, and disposes the route-scoped controllers of the previous user.
    Get.offAllNamed(RouteName.onboarding);
  }
}
