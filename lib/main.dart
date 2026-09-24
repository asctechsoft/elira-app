import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'values/app_pages.dart';
import 'values/app_theme.dart';
import 'values/route_name.dart';

/// Firebase is deliberately NOT initialised here. Spec 30 requires a visible
/// "no network / init failed" state and spec 5.1 adds remote config and
/// entitlement restore to startup; awaiting any of that before runApp() leaves
/// a first launch without connectivity on a white screen with nothing to retry
/// from. All of it runs inside the splash bootstrap pipeline instead.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const EliraApp());
}

class EliraApp extends StatelessWidget {
  const EliraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'ASC Photo AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: RouteName.splash,
      getPages: AppPages.pages,
    );
  }
}
