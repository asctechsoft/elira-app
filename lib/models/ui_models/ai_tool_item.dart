import 'package:flutter/material.dart';

class AiToolItem {
  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color bgColor;

  const AiToolItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
  });
}
