import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controller/editor_controller.dart';
import '../../../models/data_models/edit_operation.dart';
import '../../../models/data_models/user_preset.dart';
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
              return const SizedBox(height: 8);
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
          _SavedLooks(ctrl: ctrl),
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


/// The user's own saved looks, alongside the built-in presets.
///
/// A look is the colour and effect settings only, so applying one to a
/// different photo does what it did to the first. Saving is disabled until
/// there is actually something to save.
class _SavedLooks extends StatelessWidget {
  const _SavedLooks({required this.ctrl});

  final EditorController ctrl;

  @override
  Widget build(BuildContext context) => Obx(() => _build(context));

  Widget _build(BuildContext context) {
    final presets = ctrl.presets.toList();
    final canSave = !ctrl.currentState.adjust.isIdentity ||
        !ctrl.currentState.filter.isIdentity ||
        !ctrl.currentState.effects.isIdentity;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'My looks',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: canSave ? () => _save(context) : null,
                child: Opacity(
                  opacity: canSave ? 1 : 0.4,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bookmark_add_outlined,
                          size: 15, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text('Save look',
                          style: TextStyle(fontSize: 12, color: AppColors.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (presets.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Adjust the photo, then save the look to reuse it.',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            )
          else
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _LookChip(
                  preset: presets[i],
                  onTap: () => ctrl.applyPreset(presets[i]),
                  onLongPress: () => _confirmDelete(context, presets[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save(BuildContext context) async {
    final field = TextEditingController(
      text: 'Look ${ctrl.presets.length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Save this look'),
        content: TextField(
          controller: field,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(field.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    field.dispose();
    if (name != null) await ctrl.saveAsPreset(name);
  }

  Future<void> _confirmDelete(BuildContext context, UserPreset preset) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await ctrl.deletePreset(preset.id);
  }
}

class _LookChip extends StatelessWidget {
  const _LookChip({
    required this.preset,
    required this.onTap,
    required this.onLongPress,
  });

  final UserPreset preset;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.disabled),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bookmark, size: 12, color: AppColors.primary),
            const SizedBox(width: 5),
            Text(
              preset.name,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
