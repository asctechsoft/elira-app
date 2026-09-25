import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controller/create_controller.dart';
import '../../models/data_models/edit_operation.dart';
import '../../models/data_models/photo_template.dart';
import '../../services/color_matrix.dart';
import '../../services/photo_filters.dart';
import '../../values/app_colors.dart';

/// Every template, filterable by category. The "See All" behind Create.
class TemplateListScreen extends StatelessWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CreateController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: Get.back,
          child: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: AppColors.textPrimary),
        ),
        title: const Text(
          'Templates',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: Obx(
        () => Column(
          children: [
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _CategoryChip(
                    label: 'All',
                    active: ctrl.selectedCategory.value == null,
                    onTap: () => ctrl.selectCategory(null),
                  ),
                  for (final category in ctrl.categories)
                    _CategoryChip(
                      label: category.label,
                      active: ctrl.selectedCategory.value == category,
                      onTap: () => ctrl.selectCategory(category),
                    ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.72,
                ),
                itemCount: ctrl.templates.length,
                itemBuilder: (_, i) => TemplateCard(
                  template: ctrl.templates[i],
                  onTap: () => ctrl.startTemplate(ctrl.templates[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: active ? null : Border.all(color: AppColors.disabled),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? AppColors.surface : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the template's real shape and its real look: the card previews at the
/// template's own aspect ratio, tinted by the same colour matrix the editor
/// will apply. Shared with the Create tab so a template looks the same in both.
class TemplateCard extends StatelessWidget {
  const TemplateCard({
    super.key,
    required this.template,
    required this.onTap,
    this.width,
  });

  final PhotoTemplate template;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final matrix = ColorMatrix.compose(
      PhotoFilters.matrixFor(
        FilterParams(id: template.filterId, strength: template.filterStrength),
      ),
      ColorMatrix.identity,
    );

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.disabled),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: AspectRatio(
                        aspectRatio: template.aspectRatio,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.matrix(matrix),
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8A87C),
                                  Color(0xFF6B7FB3),
                                  Color(0xFF2E3A59),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimary.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          template.ratioLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              template.tagline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
