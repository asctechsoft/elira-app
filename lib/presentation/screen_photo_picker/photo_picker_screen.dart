import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import '../../controller/photo_picker_controller.dart';
import '../../values/app_colors.dart';

class PhotoPickerScreen extends StatelessWidget {
  const PhotoPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<PhotoPickerController>();
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _Header(ctrl: ctrl),
            const SizedBox(height: 16),
            Obx(() => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _TabBtn(
                        label: 'Recents',
                        icon: Icons.access_time,
                        active: ctrl.activeTab.value == PickerTab.recents,
                        onTap: () => ctrl.setTab(PickerTab.recents),
                      ),
                      const SizedBox(width: 8),
                      _TabBtn(
                        label: 'Albums',
                        icon: Icons.photo_album_outlined,
                        active: ctrl.activeTab.value == PickerTab.albums,
                        onTap: () => ctrl.setTab(PickerTab.albums),
                      ),
                      const SizedBox(width: 8),
                      _TabBtn(
                        label: 'Camera',
                        icon: Icons.camera_alt_outlined,
                        active: ctrl.activeTab.value == PickerTab.camera,
                        onTap: () => ctrl.setTab(PickerTab.camera),
                      ),
                    ],
                  ),
                )),
            Obx(() {
              final message = ctrl.errorMessage.value;
              if (message == null) return const SizedBox(height: 20);
              return _InlineNotice(
                icon: Icons.error_outline,
                color: AppColors.error,
                message: message,
                onDismiss: ctrl.clearError,
              );
            }),
            Obx(() => ctrl.hasLimitedAccess
                ? _InlineNotice(
                    icon: Icons.info_outline,
                    color: AppColors.primary,
                    message: 'You shared only some photos with ASC Photo AI.',
                    actionLabel: 'Manage',
                    onAction: ctrl.presentLimitedPicker,
                  )
                : const SizedBox.shrink()),
            Expanded(child: Obx(() => _body(ctrl))),
            Obx(() => ctrl.hasSelection
                ? _SelectionBar(ctrl: ctrl)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }

  Widget _body(PhotoPickerController ctrl) {
    if (ctrl.isLoading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    if (ctrl.permissionDenied) {
      return _PermissionDenied(onOpenSettings: ctrl.openSystemSettings, onRetry: ctrl.loadPhotos);
    }
    if (ctrl.activeTab.value == PickerTab.albums) {
      return _AlbumList(ctrl: ctrl);
    }
    if (ctrl.assets.isEmpty) {
      return const _EmptyState();
    }
    return _PhotoGrid(ctrl: ctrl);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.ctrl});

  final PhotoPickerController ctrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: const TextSpan(children: [
                    TextSpan(text: 'Choose ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.textPrimary)),
                    TextSpan(text: 'Photo', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: AppColors.primary)),
                  ]),
                ),
                Obx(() {
                  final album = ctrl.currentAlbum.value;
                  return Text(
                    album == null ? 'Pick a photo to bring to life with AI ✨' : album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGrid extends StatefulWidget {
  const _PhotoGrid({required this.ctrl});

  final PhotoPickerController ctrl;

  @override
  State<_PhotoGrid> createState() => _PhotoGridState();
}

class _PhotoGridState extends State<_PhotoGrid> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      widget.ctrl.loadMore();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Obx(() => GridView.builder(
            controller: _scroll,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
            ),
            itemCount: ctrl.assets.length + (ctrl.hasMore.value ? 4 : 0),
            itemBuilder: (_, i) {
              if (i >= ctrl.assets.length) return const _GridSkeleton();
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
                          errorBuilder: (context2, err, stack) =>
                              Container(color: AppColors.cardBg),
                        ),
                      ),
                      if (selected) ...[
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: AppColors.surface, size: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              });
            },
          )),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(4),
        ),
      );
}

class _AlbumList extends StatelessWidget {
  const _AlbumList({required this.ctrl});

  final PhotoPickerController ctrl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.albums.isEmpty) return const _EmptyState();
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ctrl.albums.length,
        separatorBuilder: (_, _) => const SizedBox(height: 4),
        itemBuilder: (_, i) {
          final album = ctrl.albums[i];
          final isCurrent = ctrl.currentAlbum.value?.id == album.id;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tileColor: isCurrent ? AppColors.actionFilters : null,
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_outlined, color: AppColors.primary, size: 20),
            ),
            title: Text(
              album.name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: FutureBuilder<int>(
              future: album.assetCountAsync,
              builder: (_, snap) => Text(
                snap.hasData ? '${snap.data} photos' : '…',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
            trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textHint),
            onTap: () => ctrl.selectAlbum(album),
          );
        },
      );
    });
  }
}

class _PermissionDenied extends StatelessWidget {
  const _PermissionDenied({required this.onOpenSettings, required this.onRetry});

  final VoidCallback onOpenSettings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            const Text(
              'Photo access is off',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ASC Photo AI needs access to your photo library to open a picture. '
              'Turn it on under Permissions → Photos, then come back.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: onOpenSettings,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 46),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                shape: const StadiumBorder(),
              ),
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'I have enabled it',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textHint),
          SizedBox(height: 10),
          Text('No photos here yet', style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.icon,
    required this.color,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.onDismiss,
  });

  final IconData icon;
  final Color color;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 12, color: color, height: 1.35),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 16, color: color),
            ),
        ],
      ),
    );
  }
}

class _SelectionBar extends StatelessWidget {
  const _SelectionBar({required this.ctrl});

  final PhotoPickerController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: [BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => ctrl.selectionTooSmallForAi
              ? const _InlineNotice(
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.proAccent,
                  message: 'This photo is small. AI enhance and upscale will give limited results.',
                )
              : const SizedBox.shrink()),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1 Photo Selected',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Obx(() => Text(
                          ctrl.selectionResolution,
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        )),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Obx(() => GestureDetector(
                    onTap: ctrl.isPreparing.value ? null : ctrl.startEditing,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: ctrl.isPreparing.value ? null : AppColors.primaryGradient,
                        color: ctrl.isPreparing.value ? AppColors.disabled : null,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ctrl.isPreparing.value
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Row(
                              children: [
                                Text(
                                  'Start Editing',
                                  style: TextStyle(
                                    color: AppColors.surface,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, color: AppColors.surface, size: 16),
                              ],
                            ),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : Border.all(color: AppColors.disabled),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: active ? AppColors.surface : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? AppColors.surface : AppColors.textSecondary,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
