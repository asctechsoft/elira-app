import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/ai/ai_service.dart';
import '../data/ai/elira_ai_service.dart';
import '../data/ai/fake_ai_service.dart';
import '../data/auth/auth_service.dart';
import '../data/auth/fake_auth_service.dart';
import '../data/auth/firebase_auth_service.dart';
import '../data/user/firestore_user_repository.dart';
import '../data/user/in_memory_user_repository.dart';
import '../data/user/user_repository.dart';
import '../values/ai_config.dart';
import '../values/feature_flags.dart';

/// Wires the auth stack. When no Firebase config has been provisioned yet
/// (`google-services.json` / `GoogleService-Info.plist` are gitignored and
/// absent on a fresh clone) `Firebase.initializeApp()` throws, and we fall back
/// to the in-memory stack so the whole flow stays runnable instead of the app
/// dying on a white screen.
class ServiceLocator {
  const ServiceLocator._();

  static bool _firebaseReady = false;

  static bool get isFirebaseReady => _firebaseReady;

  static Future<void> initFirebase() async {
    if (_firebaseReady) return;
    try {
      // No explicit options: the native google-services.json / plist is the
      // source of truth, so adding those files is all it takes to go live.
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (error) {
      _firebaseReady = false;
      debugPrint('[elira] Firebase not configured, running with in-memory auth: $error');
    }
  }

  /// Idempotent: the splash Retry button re-runs the whole pipeline, and
  /// re-registering would hand AuthController a stale service instance.
  static void registerServices() {
    if (Get.isRegistered<AuthService>() && Get.isRegistered<UserRepository>()) return;
    if (_firebaseReady) {
      Get.put<AuthService>(FirebaseAuthService(FirebaseAuth.instance), permanent: true);
      Get.put<UserRepository>(FirestoreUserRepository(FirebaseFirestore.instance), permanent: true);
    } else {
      Get.put<AuthService>(FakeAuthService(), permanent: true);
      Get.put<UserRepository>(InMemoryUserRepository(), permanent: true);
    }
    _registerAi();
  }

  /// A build with no `ELIRA_AI_ENDPOINT` normally gets a service that reports
  /// itself as unconfigured, so the UI says "not connected" up front instead
  /// of letting every run spin and then fail. While [FeatureFlags.creditsEnabled]
  /// is off for the current demo/dev phase, it simulates locally instead so
  /// every tool stays usable without a real backend. No provider key is ever
  /// read here either way — spec 25 keeps those server-side (see [AiConfig]).
  static void _registerAi() {
    if (Get.isRegistered<AiService>()) return;
    if (AiConfig.isConfigured) {
      Get.put<AiService>(
        EliraAiService(auth: Get.find<AuthService>()),
        permanent: true,
      );
    } else if (!FeatureFlags.creditsEnabled) {
      debugPrint('[elira] No ELIRA_AI_ENDPOINT: simulating AI tools locally.');
      Get.put<AiService>(FakeAiService(configured: true), permanent: true);
    } else {
      debugPrint('[elira] No ELIRA_AI_ENDPOINT: cloud AI is inactive.');
      Get.put<AiService>(FakeAiService(configured: false), permanent: true);
    }
  }
}
