import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class RecentCallsList extends StatelessWidget {
  final List<CallLog> logs;
  const RecentCallsList({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.call_outlined, color: Colors.white24, size: 36),
              SizedBox(height: 8),
              Text('No recent calls', style: TextStyle(color: Colors.white24)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: logs.take(5).map((log) => _CallLogTile(log: log)).toList(),
    );
  }
}

class _CallLogTile extends StatelessWidget {
  final CallLog log;
  const _CallLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isRisky = log.riskScore > 0.7;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRisky
              ? AppColors.danger.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isRisky
                  ? AppColors.danger.withOpacity(0.15)
                  : AppColors.card,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRisky ? Icons.warning_rounded : Icons.check_circle_rounded,
              color: isRisky ? AppColors.danger : AppColors.accent,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.callerNumber,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  log.summary,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(log.timestamp),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isRisky
                      ? AppColors.danger.withOpacity(0.2)
                      : AppColors.accent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isRisky ? 'RISK' : 'SAFE',
                  style: TextStyle(
                    color: isRisky ? AppColors.danger : AppColors.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}
