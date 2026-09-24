import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/profile_controller.dart';
import '../../values/app_colors.dart';
import '../../values/app_strings.dart';
import '../../values/feature_flags.dart';
import 'widgets/edit_profile_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProfileController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 26, color: AppColors.textPrimary)),
                    Text('Your edits, tools and settings', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Profile card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  // The Obx has to wrap the whole card: it previously covered
                  // only the stats row, so the name and badge were captured at
                  // first build and never updated after sign-in.
                  child: Obx(() => Column(
                        children: [
                          Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 32,
                                    backgroundColor: AppColors.actionFilters,
                                    backgroundImage: ctrl.photoUrl == null ? null : NetworkImage(ctrl.photoUrl!),
                                    child: ctrl.photoUrl != null
                                        ? null
                                        : Text(ctrl.initials,
                                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: AppColors.surface, blurRadius: 2, spreadRadius: 1)])),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ctrl.displayName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                                    Row(
                                      children: [
                                        Icon(
                                          ctrl.isPro ? Icons.workspace_premium : Icons.person_outline,
                                          size: 14,
                                          color: ctrl.isPro ? AppColors.proAccent : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(ctrl.badge, style: TextStyle(color: ctrl.isPro ? AppColors.proAccent : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                                      ],
                                    ),
                                    Text(
                                      ctrl.email.isEmpty ? 'Turning everyday moments into magic ✨' : ctrl.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: ctrl.isGuest ? ctrl.goToLogin : () => EditProfileSheet.show(ctrl),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                                  child: Row(
                                    children: [
                                      Text(ctrl.isGuest ? AppStrings.logIn : AppStrings.editProfile,
                                          style: const TextStyle(color: AppColors.surface, fontWeight: FontWeight.w700, fontSize: 12)),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.arrow_forward, color: AppColors.surface, size: 12),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // My Library
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('My Library', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.8,
                  // Real zeros, not invented counts: nothing writes projects,
                  // downloads or presets until the persistence phase lands.
                  children: [
                    Obx(() => _LibCard(icon: Icons.description_outlined, label: 'Drafts', count: ctrl.draftCount, color: AppColors.actionEnhance)),
                    Obx(() => _LibCard(icon: Icons.favorite_outline, label: 'Favorites', count: ctrl.favoriteCount, color: AppColors.actionRemove, iconColor: AppColors.error)),
                    Obx(() => _LibCard(icon: Icons.download_outlined, label: 'Downloads', count: ctrl.downloadCount, color: AppColors.actionFilters)),
                    Obx(() => _LibCard(icon: Icons.auto_awesome_outlined, label: 'Presets', count: ctrl.presetCount, color: AppColors.actionRetouch, iconColor: AppColors.secondary)),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Tools & Account
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text('Tools & Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      if (FeatureFlags.creditsEnabled)
                        const _SettingsRow(icon: Icons.auto_awesome, label: 'AI Credits', sub: 'View usage and get more credits', color: AppColors.secondary),
                      const _SettingsRow(icon: Icons.notifications_none, label: 'Notifications', sub: 'Choose what to be notified about', color: AppColors.error),
                      const _SettingsRow(icon: Icons.settings_outlined, label: 'Settings', sub: 'App preferences and personalisation', color: AppColors.primary),
                      const _SettingsRow(icon: Icons.help_outline, label: 'Help Center', sub: 'Get support and find answers', color: AppColors.success),
                      // Will host Delete Account (spec 25) once the flow exists.
                      const _SettingsRow(icon: Icons.security_outlined, label: 'Privacy', sub: 'Your data and privacy controls', color: AppColors.secondary),
                      _SettingsRow(
                        icon: Icons.logout,
                        label: AppStrings.signOut,
                        sub: 'You can log back in at any time',
                        color: AppColors.textSecondary,
                        isLast: true,
                        onTap: () => _confirmSignOut(ctrl),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}


class _LibCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final Color iconColor;

  const _LibCard({required this.icon, required this.label, required this.count, required this.color, this.iconColor = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
              Text('$count', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, size: 16, color: AppColors.textHint),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final bool isLast;
  final VoidCallback? onTap;

  const _SettingsRow({required this.icon, required this.label, required this.sub, required this.color, this.isLast = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
            ],
          ),
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 64),
      ],
    );
  }
}

Future<void> _confirmSignOut(ProfileController ctrl) async {
  final confirmed = await Get.dialog<bool>(
    AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(AppStrings.signOutConfirmTitle,
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      content: const Text(AppStrings.signOutConfirmBody,
          style: TextStyle(color: AppColors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () => Get.back<bool>(result: false),
          child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        TextButton(
          onPressed: () => Get.back<bool>(result: true),
          child: const Text(AppStrings.signOut,
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  if (confirmed == true) await ctrl.signOut();
}
