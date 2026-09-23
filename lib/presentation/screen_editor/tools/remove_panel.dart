import 'package:flutter/material.dart';
import '../../../values/app_colors.dart';

class RemovePanel extends StatefulWidget {
  const RemovePanel({super.key});

  @override
  State<RemovePanel> createState() => _RemovePanelState();
}

class _RemovePanelState extends State<RemovePanel> {
  bool _isBrush = true;
  double _size = 50;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Brush / Erase toggle
              _ModeBtn(label: 'Brush', icon: Icons.brush, active: _isBrush, onTap: () => setState(() => _isBrush = true)),
              const SizedBox(width: 12),
              _ModeBtn(label: 'Erase', icon: Icons.auto_fix_normal, active: !_isBrush, onTap: () => setState(() => _isBrush = false)),
              const Spacer(),
              // Size
              const Text('Size', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(width: 8),
              Text('${_size.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(activeTrackColor: AppColors.primary, inactiveTrackColor: Colors.grey.shade200, thumbColor: AppColors.primary, trackHeight: 4),
            child: Slider(value: _size, min: 5, max: 100, onChanged: (v) => setState(() => _size = v)),
          ),
          const SizedBox(height: 8),
          // Remove button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(26)),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Remove', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('✦ Powered by Advanced AI', style: TextStyle(fontSize: 11, color: AppColors.textHint)),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn({required this.label, required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withValues(alpha: 0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: active ? Border.all(color: AppColors.primary) : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: active ? AppColors.primary : AppColors.textSecondary, fontWeight: active ? FontWeight.w700 : FontWeight.w400, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
