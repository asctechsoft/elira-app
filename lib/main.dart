import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'values/app_pages.dart';
import 'values/app_theme.dart';
import 'values/route_name.dart';

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
