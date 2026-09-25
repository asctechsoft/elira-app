import 'package:get/get.dart';

import '../data/templates/recent_template_store.dart';
import '../models/data_models/photo_template.dart';
import '../values/route_name.dart';

/// What the Create tab can and cannot start.
///
/// A template here is one photo plus a shape and a look, because that is what
/// the editor is: a single-image pipeline. Collage and poster layouts need
/// several photos composited together and vector layers on top — neither
/// exists, so they are shown as not available rather than as buttons that go
/// nowhere. See [unavailable].
class CreateController extends GetxController {
  CreateController({RecentTemplateStore? recents})
      : _recents = recents ?? const PrefsRecentTemplateStore();

  final RecentTemplateStore _recents;

  final recentTemplateIds = <String>[].obs;
  final selectedCategory = Rxn<TemplateCategory>();

  /// Quick-create tiles the engine cannot honour yet, with the reason.
  static const Map<String, String> unavailable = {
    'collage': 'Collage needs several photos in one frame. The editor works on '
        'one photo at a time.',
    'poster': 'Posters need text boxes, shapes and backgrounds as layers.',
    'product_card': 'Product cards need a cut-out subject and a layout, so they '
        'wait on background removal.',
  };

  List<PhotoTemplate> get templates {
    final category = selectedCategory.value;
    if (category == null) return PhotoTemplates.all;
    return PhotoTemplates.byCategory(category);
  }

  List<TemplateCategory> get categories => TemplateCategory.values;

  /// Resolved against the catalogue, so an id left over from an older build
  /// simply disappears instead of showing an empty card.
  List<PhotoTemplate> get recentTemplates => recentTemplateIds
      .map(PhotoTemplates.byId)
      .whereType<PhotoTemplate>()
      .toList();

  bool get hasRecents => recentTemplates.isNotEmpty;

  @override
  void onInit() {
    super.onInit();
    loadRecents();
  }

  Future<void> loadRecents() async {
    recentTemplateIds.value = await _recents.load();
  }

  void selectCategory(TemplateCategory? category) =>
      selectedCategory.value = category;

  /// A template needs a photo before it means anything, so choosing one opens
  /// the picker carrying its id. The draft is then created with the template's
  /// operations already applied.
  Future<void> startTemplate(PhotoTemplate template) async {
    await _recents.remember(template.id);
    await loadRecents();
    await Get.toNamed(
      RouteName.photoPicker,
      arguments: {'template': template.id, 'tool': 'filters'},
    );
  }
}
