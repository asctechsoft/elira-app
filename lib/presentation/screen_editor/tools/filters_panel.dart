import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/edit_operation.dart';
import '../../../services/color_matrix.dart';
import '../../../services/photo_filters.dart';
import '../../../values/app_colors.dart';
import '../../common_components/tool_slider.dart';

/// Every swatch is the user's **own** photo, not a stock sample, and all of
/// them share a single small render: a filter is a colour matrix, so each
/// thumbnail is the same bytes under a different GPU filter. Nine presets
/// therefore cost one render, and they stay correct as the photo is cropped or
/// an effect is added.
class FiltersPanel extends StatelessWidget {
  const FiltersPanel({super.key, required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 96, child: Obx(() => _strip(context))),
          Obx(() {
            if (ctrl.filterId.value == FilterParams.none) {
              return const SizedBox(height: 12);
            }
            return ToolSlider(
              compact: true,
              label: 'Strength',
              min: 0,
              max: 100,
              value: ctrl.filterStrength.value,
              onChanged: ctrl.setFilterStrength,
              onChangeEnd: (_) => ctrl.commitFilter(),
            );
          }),
        ],
      ),
    );
  }

  Widget _strip(BuildContext context) {
    final base = ctrl.swatchBase.value;
    final selected = ctrl.filterId.value;
    // Read inside Obx so the swatches restack when the user's own adjustments
    // change: a preset is previewed on top of the corrections already made.
    final adjust = ctrl.adjustMatrix;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: PhotoFilters.all.length,
      separatorBuilder: (_, _) => const SizedBox(width: 10),
      itemBuilder: (_, i) {
        final filter = PhotoFilters.all[i];
        return _Swatch(
          name: filter.name,
          bytes: base,
          matrix: ColorMatrix.compose(adjust, filter.matrix),
          selected: filter.id == selected,
          onTap: () => ctrl.selectFilter(filter.id),
        );
      },
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.name,
    required this.bytes,
    required this.matrix,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Uint8List? bytes;
  final List<double> matrix;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: selected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : Border.all(color: AppColors.disabled),
            ),
            clipBehavior: Clip.antiAlias,
            child: bytes == null
                ? const Center(
                    child: Icon(Icons.image_outlined,
                        size: 20, color: AppColors.textHint),
                  )
                : ColorFiltered(
                    colorFilter: ColorFilter.matrix(matrix),
                    child: Image.memory(
                      bytes!,
                      fit: BoxFit.cover,
                      width: 64,
                      height: 64,
                      gaplessPlayback: true,
                    ),
                  ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 68,
            child: Text(
              name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
