import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/home_controller.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';
import '../screen_home/home_screen.dart';
import '../screen_ai_studio/ai_studio_screen.dart';
import '../screen_create/create_screen.dart';
import '../screen_profile/profile_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeController>();
    return Obx(() => Scaffold(
          body: IndexedStack(
            index: ctrl.currentTabIndex.value == 1 ? 0 : ctrl.currentTabIndex.value > 1 ? ctrl.currentTabIndex.value - 1 : ctrl.currentTabIndex.value,
            children: const [HomeScreen(), AiStudioScreen(), CreateScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: ctrl.currentTabIndex.value,
            onTap: (i) {
              if (i == 1) {
                Get.toNamed(RouteName.photoPicker);
              } else {
                ctrl.changeTab(i);
              }
            },
          ),
        ));
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(icon: Icons.home_rounded, label: 'Home', active: currentIndex == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.tune_rounded, label: 'Edit', active: currentIndex == 1, onTap: () => onTap(1)),
              _NavItemAI(active: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Create', active: currentIndex == 3, onTap: () => onTap(3)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Me', active: currentIndex == 4, onTap: () => onTap(4)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? AppColors.primary : AppColors.textHint, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primary : AppColors.textHint,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
            if (active)
              Container(
                margin: const EdgeInsets.only(top: 3),
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItemAI extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _NavItemAI({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: active ? const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]) : null,
                color: active ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.auto_awesome, color: active ? Colors.white : AppColors.textHint, size: 22),
            ),
            const SizedBox(height: 2),
            Text('AI', style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.textHint, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
