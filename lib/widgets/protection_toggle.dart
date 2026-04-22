import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ProtectionToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const ProtectionToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.accent,
      activeTrackColor: AppColors.accent.withOpacity(0.3),
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.white12,
    );
  }
}
