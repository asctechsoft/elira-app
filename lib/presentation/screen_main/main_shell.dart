import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/home_controller.dart';
import '../../values/app_colors.dart';
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
            index: ctrl.currentTabIndex.value,
            children: const [HomeScreen(), AiStudioScreen(), CreateScreen(), ProfileScreen()],
          ),
          bottomNavigationBar: _BottomNav(
            currentIndex: ctrl.currentTabIndex.value,
            onTap: ctrl.changeTab,
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
              _NavItem(
                icon: Icons.auto_awesome_rounded,
                label: 'AI',
                active: currentIndex == 1,
                onTap: () => onTap(1),
                activeGradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
              ),
              _NavItem(icon: Icons.add_circle_outline_rounded, label: 'Sample', active: currentIndex == 2, onTap: () => onTap(2)),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Me', active: currentIndex == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Every item shares the same icon-box size and label position, so the row
/// lines up regardless of which item (including the branded AI one) is
/// active — a bare icon and a boxed icon previously sat at different heights.
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  /// The AI item keeps its branded gradient when active; every other item
  /// gets a plain tinted pill instead.
  final Gradient? activeGradient;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.activeGradient,
  });

  @override
  Widget build(BuildContext context) {
    final branded = activeGradient != null;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: 44,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: active ? activeGradient : null,
                color: active && !branded ? AppColors.primary.withValues(alpha: 0.12) : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: active ? (branded ? Colors.white : AppColors.primary) : AppColors.textHint,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: active ? AppColors.primary : AppColors.textHint,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
