import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

class EmergencyDialRow extends StatelessWidget {
  const EmergencyDialRow({super.key});

  @override
  Widget build(BuildContext context) {
    final numbers = [
      (
        '119',
        '소방/구급',
        Icons.local_fire_department_rounded,
        const Color(0xFFFF6B35),
      ),
      ('112', '경찰', Icons.local_police_rounded, const Color(0xFF1A73E8)),
      ('1301', '금융범죄', Icons.account_balance_rounded, const Color(0xFF9C27B0)),
      ('182', '사기신고', Icons.report_rounded, AppColors.warning),
    ];

    return Row(
      children: numbers
          .map(
            (n) => Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _EmergencyButton(
                  number: n.$1,
                  label: n.$2,
                  icon: n.$3,
                  color: n.$4,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _EmergencyButton extends StatelessWidget {
  final String number, label;
  final IconData icon;
  final Color color;
  const _EmergencyButton({
    required this.number,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri(scheme: 'tel', path: number);
        if (await canLaunchUrl(uri)) launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              number,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
