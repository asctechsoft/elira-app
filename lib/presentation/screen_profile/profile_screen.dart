import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/profile_controller.dart';
import '../../values/app_colors.dart';

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
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              const CircleAvatar(radius: 32, backgroundColor: Color(0xFFE8F0FF), child: Icon(Icons.person, size: 32, color: AppColors.primary)),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(width: 12, height: 12, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.white, blurRadius: 2, spreadRadius: 1)])),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Emma Carter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
                                Row(
                                  children: [
                                    const Icon(Icons.workspace_premium, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    const Text('Pro Member', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600, fontSize: 13)),
                                  ],
                                ),
                                const Text('Turning everyday moments into magic ✨', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(20)),
                            child: const Row(
                              children: [
                                Text('Manage Pro', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 12),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Obx(() => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _StatItem(value: '${ctrl.projectCount.value}', label: 'Projects', icon: Icons.layers_outlined),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              _StatItem(value: '${ctrl.favoriteCount.value}', label: 'Favorites', icon: Icons.favorite_outline, iconColor: Colors.red),
                              Container(width: 1, height: 40, color: Colors.grey.shade200),
                              _StatItem(value: '${ctrl.aiCredits.value}', label: 'AI Credits', icon: Icons.auto_awesome, iconColor: Colors.amber),
                            ],
                          )),
                    ],
                  ),
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
                  children: const [
                    _LibCard(icon: Icons.description_outlined, label: 'Drafts', count: 12, color: Color(0xFFDCFAF0)),
                    _LibCard(icon: Icons.favorite_outline, label: 'Favorites', count: 56, color: Color(0xFFFFECEC), iconColor: Colors.red),
                    _LibCard(icon: Icons.download_outlined, label: 'Downloads', count: 24, color: Color(0xFFE8F0FF)),
                    _LibCard(icon: Icons.auto_awesome_outlined, label: 'Presets', count: 18, color: Color(0xFFEEEAFF), iconColor: Color(0xFF6B4FDB)),
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
                    children: const [
                      _SettingsRow(icon: Icons.auto_awesome, label: 'AI Credits', sub: 'View usage and get more credits', color: Color(0xFF6B4FDB)),
                      _SettingsRow(icon: Icons.workspace_premium, label: 'Subscription', sub: 'Manage your plan and benefits', color: Colors.amber),
                      _SettingsRow(icon: Icons.notifications_none, label: 'Notifications', sub: 'Choose what to be notified about', color: Colors.red),
                      _SettingsRow(icon: Icons.settings_outlined, label: 'Settings', sub: 'App preferences and personalisation', color: AppColors.primary),
                      _SettingsRow(icon: Icons.help_outline, label: 'Help Center', sub: 'Get support and find answers', color: Color(0xFF00875A)),
                      _SettingsRow(icon: Icons.security_outlined, label: 'Privacy', sub: 'Your data and privacy controls', color: Color(0xFF6B4FDB), isLast: true),
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

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _StatItem({required this.value, required this.label, required this.icon, this.iconColor = AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textPrimary)),
          ],
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
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

  const _SettingsRow({required this.icon, required this.label, required this.sub, required this.color, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
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
        if (!isLast) const Divider(height: 1, indent: 64),
      ],
    );
  }
}
