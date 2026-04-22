import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RiskMeter extends StatelessWidget {
  final double score; // 0.0 to 1.0
  const RiskMeter({super.key, required this.score});

  Color get _color {
    if (score > 0.7) return AppColors.danger;
    if (score > 0.4) return AppColors.warning;
    return AppColors.accent;
  }

  String get _label {
    if (score > 0.7) return 'HIGH RISK';
    if (score > 0.4) return 'CAUTION';
    return 'SAFE';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text('Risk', style: TextStyle(color: Colors.white38, fontSize: 12)),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(_color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 10),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: _color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              child: Text(_label),
            ),
          ],
        ),
      ),
    );
  }
}
