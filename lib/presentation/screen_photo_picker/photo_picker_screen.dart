import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../controller/photo_picker_controller.dart';
import '../../values/app_colors.dart';
import '../../values/route_name.dart';

class PhotoPickerScreen extends StatelessWidget {
  const PhotoPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PhotoPickerController>();
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
                  GestureDetector(
                    onTap: Get.back,
                    child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: const TextSpan(children: [
                          TextSpan(text: 'Choose ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
                          TextSpan(text: 'Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                        ]),
                      ),
                      const Text('Pick a photo to bring to life with AI ✨',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab bar
            Obx(() => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _TabBtn(label: 'Recents', icon: Icons.access_time, active: ctrl.activeTab.value == 0, onTap: () => ctrl.setTab(0)),
                      const SizedBox(width: 8),
                      _TabBtn(label: 'Albums', icon: Icons.photo_album_outlined, active: ctrl.activeTab.value == 1, onTap: () => ctrl.setTab(1)),
                      const SizedBox(width: 8),
                      _TabBtn(label: 'Camera', icon: Icons.camera_alt_outlined, active: ctrl.activeTab.value == 2, onTap: () => ctrl.setTab(2)),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Photo grid
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (ctrl.permissionDenied.value) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        const Text('Photo access denied', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: PhotoManager.openSetting,
                          child: const Text('Open Settings'),
                        ),
                      ],
                    ),
                  );
                }
                if (ctrl.assets.isEmpty) {
                  return const Center(
                    child: Text('No photos found', style: TextStyle(color: AppColors.textSecondary)),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 3,
                      crossAxisSpacing: 3,
                    ),
                    itemCount: ctrl.assets.length,
                    itemBuilder: (_, i) {
                      final asset = ctrl.assets[i];
                      return Obx(() {
                        final selected = ctrl.selectedAsset.value?.id == asset.id;
                        return GestureDetector(
                          onTap: () => ctrl.selectAsset(asset),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AssetEntityImage(
                                  asset,
                                  isOriginal: false,
                                  thumbnailSize: const ThumbnailSize.square(200),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context2, err, stack) => Container(color: Colors.grey.shade200),
                                ),
                              ),
                              if (selected)
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.primary, width: 3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              if (selected)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                                  ),
                                ),
                            ],
                          ),
                        );
                      });
                    },
                  ),
                );
              }),
            ),

            // Bottom action bar
            Obx(() => ctrl.hasSelection
                ? Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AssetEntityImage(
                              ctrl.selectedAsset.value!,
                              isOriginal: false,
                              thumbnailSize: const ThumbnailSize.square(96),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('1 Photo Selected', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                              Text('Ready to create something amazing?', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final asset = ctrl.selectedAsset.value!;
                            final file = await asset.file;
                            if (file != null) {
                              Get.toNamed(RouteName.editor, arguments: file.path);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              children: [
                                Text('Start Editing', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          color: active ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 13, color: active ? Colors.white : AppColors.textSecondary, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
