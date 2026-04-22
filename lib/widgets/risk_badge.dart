import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RiskBadge extends StatelessWidget {
  final double score;
  const RiskBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score > 0.7
        ? AppColors.danger
        : score > 0.4
        ? AppColors.warning
        : AppColors.accent;
    final label = score > 0.7
        ? 'HIGH'
        : score > 0.4
        ? 'MED'
        : 'LOW';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
