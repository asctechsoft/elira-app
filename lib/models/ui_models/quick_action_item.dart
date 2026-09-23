import 'package:flutter/material.dart';

class QuickActionItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  const QuickActionItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
  });
}
