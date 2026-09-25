import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/export_controller.dart';
import '../../services/export_service.dart';
import '../../services/image_pipeline.dart';
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
                  Obx(() => _Preview(ctrl: ctrl)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Obx(() => _AiBadge(
                          label: ctrl.result.value == null
                              ? 'Preview'
                              : ctrl.result.value!.resolutionLabel,
                        )),
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
                      trailing: Obx(() => Text(
                          ctrl.isQualityAdjustable
                              ? '${ctrl.quality.value.toInt()}%'
                              : 'Lossless',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary))),
                    ),
                    // PNG is lossless, so the slider is disabled rather than
                    // left live over a value that would be ignored.
                    Obx(() => Slider(
                          value: ctrl.quality.value,
                          min: 10,
                          max: 100,
                          activeColor: AppColors.primary,
                          inactiveColor: Colors.grey.shade200,
                          onChanged: ctrl.isQualityAdjustable ? ctrl.setQuality : null,
                        )),

                    // Resolution
                    _SettingRow(
                      icon: Icons.aspect_ratio_outlined,
                      label: 'Resolution',
                      sub: 'Great for social media and printing',
                      trailing: Obx(() => PopupMenuButton<ExportSize>(
                            onSelected: ctrl.setSize,
                            itemBuilder: (_) => ExportSize.values
                                .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
                                .toList(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                children: [
                                  // Derived from the real crop and rotation,
                                  // not a number frozen into the mockup.
                                  Text(ctrl.resolutionLabel,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 16),
                                ],
                              ),
                            ),
                          )),
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
                          label: ctrl.isExporting.value
                              ? ctrl.stageLabel
                              : 'Export Photo',
                          isLoading: ctrl.isExporting.value,
                          icon: const Icon(Icons.upload_outlined, color: Colors.white),
                          onTap: ctrl.exportPhoto,
                        )),
                    Obx(() {
                      final message = ctrl.errorMessage.value;
                      if (message == null) return const SizedBox.shrink();
                      return _Notice(message: message, onDismiss: ctrl.clearError);
                    }),
                    Obx(() {
                      final done = ctrl.result.value;
                      if (done == null) return const SizedBox.shrink();
                      return _Done(
                        result: done,
                        savedToGallery: ctrl.savedToGallery.value,
                        onShare: ctrl.share,
                      );
                    }),
                    const SizedBox(height: 24),

                    // Share to social
                    const Text('Share to Social Media', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 12),
                    // Each of these opens the system share sheet. Deep-linking
                    // into a specific app needs that app's own SDK and review
                    // process; the sheet is what actually works today.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SocialBtn(label: 'Instagram', icon: Icons.camera_alt, color: const Color(0xFFE1306C), onTap: ctrl.share),
                        _SocialBtn(label: 'TikTok', icon: Icons.music_note, color: Colors.black, onTap: ctrl.share),
                        _SocialBtn(label: 'Facebook', icon: Icons.facebook, color: const Color(0xFF1877F2), onTap: ctrl.share),
                        _SocialBtn(label: 'More', icon: Icons.more_horiz, color: Colors.grey, onTap: ctrl.share),
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
  final VoidCallback onTap;

  const _SocialBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}

/// The finished frame: the editor's own preview under the same colour matrix
/// the canvas uses, swapped for the real exported bytes once there are some.
class _Preview extends StatelessWidget {
  const _Preview({required this.ctrl});

  final ExportController ctrl;

  @override
  Widget build(BuildContext context) {
    final exported = ctrl.result.value;
    final decoration = BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(20),
    );

    if (exported != null) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Image.memory(exported.bytes, fit: BoxFit.contain, gaplessPlayback: true),
      );
    }

    final bytes = ctrl.previewBytes;
    if (bytes == null) {
      return Container(
        height: 260,
        width: double.infinity,
        decoration: decoration,
        child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 48)),
      );
    }

    final matrix = ctrl.colorMatrix;
    final image = Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
    return Container(
      height: 260,
      width: double.infinity,
      decoration: decoration,
      clipBehavior: Clip.antiAlias,
      child: ImagePipeline.isIdentityMatrix(matrix)
          ? image
          : ColorFiltered(colorFilter: ColorFilter.matrix(matrix), child: image),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
          GestureDetector(onTap: onDismiss, child: const Icon(Icons.close, size: 15, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done({
    required this.result,
    required this.savedToGallery,
    required this.onShare,
  });

  final ExportResult result;
  final bool savedToGallery;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.success, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  savedToGallery ? 'Saved to your gallery' : 'Exported',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                ),
                Text(
                  '${result.resolutionLabel} · ${result.fileSizeLabel}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onShare,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(18)),
              child: const Text('Share', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
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
