import 'package:get/get.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoPickerController extends GetxController {
  final assets = <AssetEntity>[].obs;
  final selectedAsset = Rx<AssetEntity?>(null);
  final activeTab = 0.obs;
  final isLoading = true.obs;
  final permissionDenied = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadPhotos();
  }

  Future<void> loadPhotos() async {
    isLoading.value = true;
    final result = await PhotoManager.requestPermissionExtend();
    if (!result.isAuth) {
      permissionDenied.value = true;
      isLoading.value = false;
      return;
    }
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: FilterOptionGroup(
        orders: [const OrderOption(type: OrderOptionType.createDate, asc: false)],
      ),
    );
    if (albums.isEmpty) {
      isLoading.value = false;
      return;
    }
    final recent = albums.firstWhere(
      (a) => a.isAll,
      orElse: () => albums.first,
    );
    final list = await recent.getAssetListPaged(page: 0, size: 120);
    assets.value = list;
    isLoading.value = false;
  }

  void selectAsset(AssetEntity asset) {
    if (selectedAsset.value?.id == asset.id) {
      selectedAsset.value = null;
    } else {
      selectedAsset.value = asset;
    }
  }

  void setTab(int index) => activeTab.value = index;

  bool get hasSelection => selectedAsset.value != null;
}
