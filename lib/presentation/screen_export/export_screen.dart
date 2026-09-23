import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/export_controller.dart';
import '../../values/app_colors.dart';
import '../common_components/primary_button.dart';

class ExportScreen extends StatelessWidget {
  const ExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ExportController>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  GestureDetector(onTap: Get.back, child: const Icon(Icons.arrow_back_ios_new, size: 20)),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: 'Export & ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
                          TextSpan(text: 'Share', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                        ]),
                      ),
                      const Text('Save your masterpiece and share it with the world ✨',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Image preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Stack(
                children: [
                  Container(
                    height: 260,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20)),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                      child: const Row(
                        children: [
                          Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text('Preview', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 12,
                    left: 12,
                    child: _AiBadge(label: 'AI Enhanced'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export settings
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Export Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.textPrimary)),
                    const SizedBox(height: 16),

                    // Format
                    _SettingRow(
                      icon: Icons.image_outlined,
                      label: 'File Format',
                      sub: 'Choose the best format for your needs',
                      trailing: Obx(() => Row(
                            children: [
                              _FormatBtn(label: 'JPEG', active: ctrl.isJpeg.value, onTap: () { if (!ctrl.isJpeg.value) ctrl.toggleFormat(); }),
                              const SizedBox(width: 6),
                              _FormatBtn(label: 'PNG', active: !ctrl.isJpeg.value, onTap: () { if (ctrl.isJpeg.value) ctrl.toggleFormat(); }),
                            ],
                          )),
                    ),
                    const SizedBox(height: 12),

                    // Quality
                    _SettingRow(
                      icon: Icons.layers_outlined,
                      label: 'Image Quality',
                      sub: 'Higher quality, larger file size',
                      trailing: Obx(() => Text('${ctrl.quality.value.toInt()}%',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary))),
                    ),
                    Obx(() => Slider(
                          value: ctrl.quality.value,
                          min: 10,
                          max: 100,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.grey.shade200,
                          onChanged: ctrl.setQuality,
                        )),

                    // Resolution
                    _SettingRow(
                      icon: Icons.aspect_ratio_outlined,
                      label: 'Resolution',
                      sub: 'Great for social media and printing',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          children: [
                            Text('Original (3024 × 4032)', style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, size: 16),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Watermark
                    _SettingRow(
                      icon: Icons.copyright_outlined,
                      label: 'Add Watermark',
                      sub: 'Show love for ASC Photo AI',
                      trailing: Obx(() => Switch(
                            value: ctrl.addWatermark.value,
                            onChanged: ctrl.toggleWatermark,
                            activeThumbColor: AppColors.primary,
                          )),
                    ),
                    const SizedBox(height: 24),

                    // Export button
                    Obx(() => PrimaryButton(
                          label: 'Export Photo',
                          isLoading: ctrl.isExporting.value,
                          icon: const Icon(Icons.upload_outlined, color: Colors.white),
                          onTap: ctrl.exportPhoto,
                        )),
                    const SizedBox(height: 24),

                    // Share to social
                    const Text('Share to Social Media', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        _SocialBtn(label: 'Instagram', icon: Icons.camera_alt, color: Color(0xFFE1306C)),
                        _SocialBtn(label: 'TikTok', icon: Icons.music_note, color: Colors.black),
                        _SocialBtn(label: 'Facebook', icon: Icons.facebook, color: Color(0xFF1877F2)),
                        _SocialBtn(label: 'More', icon: Icons.more_horiz, color: Colors.grey),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Widget trailing;

  const _SettingRow({required this.icon, required this.label, required this.sub, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: AppColors.primary, size: 18),
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
        trailing,
      ],
    );
  }
}

class _FormatBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FormatBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border.all(color: active ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SocialBtn({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AiBadge extends StatelessWidget {
  final String label;

  const _AiBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
