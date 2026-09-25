import 'edit_operation.dart';

enum TemplateCategory { social, portrait, product, cinematic }

extension TemplateCategoryX on TemplateCategory {
  String get label => switch (this) {
        TemplateCategory.social => 'Social',
        TemplateCategory.portrait => 'Portrait',
        TemplateCategory.product => 'Product',
        TemplateCategory.cinematic => 'Cinematic',
      };
}

/// A starting point for one photo: a shape and a look.
///
/// It is deliberately **not** a new kind of document. A template compiles down
/// to ordinary [EditOperation]s, which means applying one costs nothing new,
/// every step of it is undoable, and it is saved and reopened by the same code
/// that handles a hand-made edit. Nothing in the editor knows templates exist.
class PhotoTemplate {
  const PhotoTemplate({
    required this.id,
    required this.name,
    required this.tagline,
    required this.category,
    required this.aspectRatio,
    required this.ratioLabel,
    this.adjust = AdjustParams.identity,
    this.filterId = FilterParams.none,
    this.filterStrength = 100,
    this.effects = EffectParams.identity,
  });

  final String id;
  final String name;
  final String tagline;
  final TemplateCategory category;

  /// Width / height of the finished photo.
  final double aspectRatio;

  /// How the ratio is written on the card, e.g. "9:16".
  final String ratioLabel;

  final AdjustParams adjust;
  final String filterId;
  final double filterStrength;
  final EffectParams effects;

  /// The operations this template becomes, for a photo of the given size.
  ///
  /// The crop has to be computed here rather than stored: a 9:16 crop is a
  /// different rectangle on a landscape photo than on a portrait one, and the
  /// rectangle is what gets saved.
  List<EditOperation> toOperations({
    required int sourceWidth,
    required int sourceHeight,
  }) {
    final operations = <EditOperation>[];

    if (sourceWidth > 0 && sourceHeight > 0) {
      final geometry = centeredCrop(
        frameAspect: sourceWidth / sourceHeight,
        ratio: aspectRatio,
      );
      if (geometry.hasCrop) {
        operations.add(EditOperation(
          type: EditOperationType.crop,
          label: 'Crop',
          params: geometry.toMap(),
        ));
      }
    }

    if (filterId != FilterParams.none) {
      operations.add(EditOperation(
        type: EditOperationType.filter,
        label: name,
        params: FilterParams(id: filterId, strength: filterStrength).toMap(),
      ));
    }

    if (!adjust.isIdentity) {
      operations.add(EditOperation(
        type: EditOperationType.adjust,
        label: 'Adjust',
        params: adjust.toMap(),
      ));
    }

    if (!effects.isIdentity) {
      operations.add(EditOperation(
        type: EditOperationType.effects,
        label: 'Effects',
        params: effects.toMap(),
      ));
    }

    return operations;
  }

  /// What the draft stores, so the editor restores a template exactly the way
  /// it restores a saved project.
  Map<String, dynamic> toAdjustments({
    required int sourceWidth,
    required int sourceHeight,
  }) =>
      {
        'v': 1,
        'templateId': id,
        'operations': toOperations(
          sourceWidth: sourceWidth,
          sourceHeight: sourceHeight,
        ).map((op) => op.toMap()).toList(),
      };

  /// The largest centred rectangle of [ratio] that fits a frame of
  /// [frameAspect], as a normalised crop.
  static GeometryParams centeredCrop({
    required double frameAspect,
    required double ratio,
  }) {
    if (frameAspect <= 0 || ratio <= 0) return GeometryParams.identity;

    var width = 1.0;
    var height = 1.0;
    if (ratio > frameAspect) {
      height = frameAspect / ratio;
    } else {
      width = ratio / frameAspect;
    }
    return GeometryParams(
      left: (1 - width) / 2,
      top: (1 - height) / 2,
      right: (1 + width) / 2,
      bottom: (1 + height) / 2,
    );
  }
}

/// Shipped with the app rather than fetched.
///
/// TODO section 8 allowed "Firestore or local asset". Local, because a
/// template is a handful of numbers, and fetching them would mean the Create
/// tab is empty on a first run with no network — an empty state for data that
/// never changes between releases.
class PhotoTemplates {
  const PhotoTemplates._();

  static const List<PhotoTemplate> all = [
    PhotoTemplate(
      id: 'story_clean',
      name: 'Clean Story',
      tagline: 'Bright and simple',
      category: TemplateCategory.social,
      aspectRatio: 9 / 16,
      ratioLabel: '9:16',
      adjust: AdjustParams(brightness: 12, contrast: 14, saturation: 10),
    ),
    PhotoTemplate(
      id: 'story_film',
      name: 'Film Story',
      tagline: 'Faded with grain',
      category: TemplateCategory.social,
      aspectRatio: 9 / 16,
      ratioLabel: '9:16',
      filterId: 'fade',
      filterStrength: 80,
      effects: EffectParams(grain: 35, vignette: 25),
    ),
    PhotoTemplate(
      id: 'post_vivid',
      name: 'Vivid Post',
      tagline: 'Punchy square',
      category: TemplateCategory.social,
      aspectRatio: 1,
      ratioLabel: '1:1',
      filterId: 'vibrant',
      filterStrength: 85,
      adjust: AdjustParams(sharpness: 20),
    ),
    PhotoTemplate(
      id: 'post_mono',
      name: 'Mono Post',
      tagline: 'Black and white',
      category: TemplateCategory.social,
      aspectRatio: 1,
      ratioLabel: '1:1',
      filterId: 'bw',
      adjust: AdjustParams(contrast: 18),
    ),
    PhotoTemplate(
      id: 'portrait_golden',
      name: 'Golden Portrait',
      tagline: 'Warm and soft',
      category: TemplateCategory.portrait,
      aspectRatio: 4 / 5,
      ratioLabel: '4:5',
      filterId: 'golden_hour',
      filterStrength: 75,
      effects: EffectParams(vignette: 30, glow: 20),
    ),
    PhotoTemplate(
      id: 'portrait_soft',
      name: 'Soft Portrait',
      tagline: 'Gentle and pastel',
      category: TemplateCategory.portrait,
      aspectRatio: 4 / 5,
      ratioLabel: '4:5',
      filterId: 'aesthetic',
      filterStrength: 70,
      adjust: AdjustParams(sharpness: -10),
    ),
    PhotoTemplate(
      id: 'product_clean',
      name: 'Clean Product',
      tagline: 'Crisp and neutral',
      category: TemplateCategory.product,
      aspectRatio: 1,
      ratioLabel: '1:1',
      adjust: AdjustParams(brightness: 18, contrast: 12, sharpness: 35),
    ),
    PhotoTemplate(
      id: 'cinematic_wide',
      name: 'Cinematic Wide',
      tagline: 'Teal and orange',
      category: TemplateCategory.cinematic,
      aspectRatio: 16 / 9,
      ratioLabel: '16:9',
      filterId: 'cinematic',
      effects: EffectParams(vignette: 35),
    ),
    PhotoTemplate(
      id: 'cinematic_scope',
      name: 'Widescreen',
      tagline: 'Letterbox crop',
      category: TemplateCategory.cinematic,
      aspectRatio: 2.39,
      ratioLabel: '2.39:1',
      filterId: 'cinematic',
      filterStrength: 70,
      adjust: AdjustParams(contrast: 10),
    ),
  ];

  /// Unknown ids resolve to null rather than throwing: a project saved by a
  /// newer build must still open.
  static PhotoTemplate? byId(String id) {
    for (final template in all) {
      if (template.id == id) return template;
    }
    return null;
  }

  static List<PhotoTemplate> byCategory(TemplateCategory category) =>
      all.where((t) => t.category == category).toList();
}
