import 'package:flutter/material.dart';

import '../../../../values/app_colors.dart';

/// Shown by the tool panels that cannot work until the cloud AI service is
/// connected (spec 25: the provider keys are server-side, so there is nothing
/// the app can do on its own).
///
/// This deliberately states that the tool is not connected yet instead of
/// running a timer and reporting success. A control that looks like it worked
/// and did nothing is worse than one that says what it needs.
class AiGate extends StatelessWidget {
  const AiGate({
    super.key,
    required this.title,
    required this.description,
    required this.bullets,
    this.credits,
  });

  final String title;
  final String description;
  final List<String> bullets;

  /// What one run will cost once billing is live, if known.
  final int? credits;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: AppColors.surface, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (credits != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.disabled),
                  ),
                  child: Text(
                    '$credits credits',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ...bullets.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 4, right: 7),
                    child: Icon(Icons.circle, size: 5, color: AppColors.textHint),
                  ),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.disabled),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off_outlined,
                    size: 15, color: AppColors.textHint),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Not connected yet — this tool runs on the cloud service.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textHint),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
