import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/data_models/edit_project.dart';
import '../services/project_draft_service.dart';
import '../values/route_name.dart';

enum PickerTab { recents, albums, camera }

enum GalleryAccess { unknown, granted, limited, denied }

class PhotoPickerController extends GetxController {
  PhotoPickerController({ProjectDraftService? drafts, ImagePicker? camera})
      : _drafts = drafts ?? ProjectDraftService(),
        _camera = camera ?? ImagePicker();

  final ProjectDraftService _drafts;
  final ImagePicker _camera;

  static const int _pageSize = 90;

  final assets = <AssetEntity>[].obs;
  final albums = <AssetPathEntity>[].obs;
  final currentAlbum = Rxn<AssetPathEntity>();
  final selectedAsset = Rx<AssetEntity?>(null);
  final activeTab = PickerTab.recents.obs;
  final access = GalleryAccess.unknown.obs;
  final isLoading = true.obs;
  final isLoadingMore = false.obs;
  final hasMore = true.obs;
  final isPreparing = false.obs;
  final errorMessage = RxnString();

  /// Set when the user arrived from a Home quick action; forwarded to the
  /// editor so it opens on the tool they asked for instead of the default.
  String? requestedTool;

  int _page = 0;

  bool get hasSelection => selectedAsset.value != null;

  bool get permissionDenied => access.value == GalleryAccess.denied;

  /// iOS "selected photos" and Android 14 partial access: the grid works but
  /// only shows what the user shared, so the UI has to offer a way to widen it.
  bool get hasLimitedAccess => access.value == GalleryAccess.limited;

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is Map && arg['tool'] is String) requestedTool = arg['tool'] as String;
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    isLoading.value = true;
    errorMessage.value = null;

    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      access.value = GalleryAccess.denied;
      isLoading.value = false;
      return;
    }
    access.value = permission == PermissionState.limited
        ? GalleryAccess.limited
        : GalleryAccess.granted;

    try {
      final paths = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
        ),
      );
      albums.value = paths;

      if (paths.isEmpty) {
        assets.clear();
        hasMore.value = false;
        isLoading.value = false;
        return;
      }

      final recent = paths.firstWhere((a) => a.isAll, orElse: () => paths.first);
      await selectAlbum(recent, keepLoading: true);
    } catch (error) {
      debugPrint('[picker] load failed: $error');
      errorMessage.value = 'Could not read your photo library.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectAlbum(AssetPathEntity album, {bool keepLoading = false}) async {
    if (!keepLoading) isLoading.value = true;
    currentAlbum.value = album;
    _page = 0;
    hasMore.value = true;
    selectedAsset.value = null;

    final first = await album.getAssetListPaged(page: 0, size: _pageSize);
    assets.value = first;
    hasMore.value = first.length == _pageSize;

    if (!keepLoading) isLoading.value = false;
    if (activeTab.value == PickerTab.albums) activeTab.value = PickerTab.recents;
  }

  /// Called as the grid nears its end. The old implementation fetched exactly
  /// one page of 120 and silently hid everything beyond it.
  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;
    final album = currentAlbum.value;
    if (album == null) return;

    isLoadingMore.value = true;
    try {
      final next = await album.getAssetListPaged(page: _page + 1, size: _pageSize);
      if (next.isEmpty) {
        hasMore.value = false;
      } else {
        _page++;
        assets.addAll(next);
        hasMore.value = next.length == _pageSize;
      }
    } catch (error) {
      debugPrint('[picker] loadMore failed: $error');
      hasMore.value = false;
    } finally {
      isLoadingMore.value = false;
    }
  }

  void selectAsset(AssetEntity asset) {
    selectedAsset.value = selectedAsset.value?.id == asset.id ? null : asset;
  }

  void setTab(PickerTab tab) {
    activeTab.value = tab;
    if (tab == PickerTab.camera) captureFromCamera();
  }

  /// True when the selected photo is too small for AI upscale/enhance to give
  /// a good result. Shown as a warning, never as a block.
  bool get selectionTooSmallForAi {
    final asset = selectedAsset.value;
    if (asset == null) return false;
    final pixels = asset.width * asset.height;
    return pixels > 0 && pixels < ProjectDraftService.minPixelsForAi;
  }

  String get selectionResolution {
    final asset = selectedAsset.value;
    if (asset == null) return '';
    return '${asset.width} × ${asset.height}';
  }

  Future<void> captureFromCamera() async {
    errorMessage.value = null;

    // CAMERA is declared in the manifest, so Android requires the runtime grant
    // before the capture intent will return anything.
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      errorMessage.value = status.isPermanentlyDenied
          ? 'Camera access is blocked. Enable it in Settings to take a photo.'
          : 'Camera access is needed to take a photo.';
      activeTab.value = PickerTab.recents;
      return;
    }

    try {
      final shot = await _camera.pickImage(source: ImageSource.camera);
      if (shot == null) {
        activeTab.value = PickerTab.recents;
        return;
      }
      await _openEditor(() => _drafts.createFromFile(File(shot.path), tool: requestedTool));
    } catch (error) {
      debugPrint('[picker] camera failed: $error');
      errorMessage.value = 'Could not open the camera.';
      activeTab.value = PickerTab.recents;
    }
  }

  Future<void> startEditing() async {
    final asset = selectedAsset.value;
    if (asset == null) return;
    await _openEditor(() => _drafts.createFromAsset(asset, tool: requestedTool));
  }

  Future<void> _openEditor(Future<EditProject> Function() build) async {
    if (isPreparing.value) return;
    isPreparing.value = true;
    try {
      final project = await build();
      Get.toNamed(RouteName.editor, arguments: project);
    } on ProjectDraftFailure catch (failure) {
      errorMessage.value = failure.message;
    } catch (error) {
      debugPrint('[picker] draft failed: $error');
      errorMessage.value = 'Could not prepare that photo for editing.';
    } finally {
      isPreparing.value = false;
    }
  }

  Future<void> openSystemSettings() => PhotoManager.openSetting();

  /// iOS only in practice: lets the user add more photos to the shared subset
  /// without leaving the app.
  Future<void> presentLimitedPicker() async {
    await PhotoManager.presentLimited();
    await loadPhotos();
  }

  void clearError() => errorMessage.value = null;
}
