import 'package:flutter/material.dart';

import '../../../../values/app_colors.dart';

/// The one selectable pill every tool panel uses. Previously each panel drew
/// its own, which is why the active state looked different on every tab.
class ToolChip extends StatelessWidget {
  const ToolChip({
    super.key,
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
    this.badge,
    this.enabled = true,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  /// A small dot shown when the control is non-zero, so a value set on a tab
  /// the user is not currently looking at is still visible.
  final bool? badge;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? AppColors.textHint
        : active
            ? AppColors.surface
            : AppColors.textSecondary;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: active ? AppColors.primaryGradient : null,
            color: active ? null : AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: active ? null : Border.all(color: AppColors.disabled),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: foreground),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: foreground,
                ),
              ),
              if (badge == true) ...[
                const SizedBox(width: 5),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? AppColors.surface : AppColors.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
