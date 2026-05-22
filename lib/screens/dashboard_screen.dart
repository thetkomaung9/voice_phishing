import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../services/native_channel_service.dart';
import '../models/phishing_assessment.dart';
import '../theme/app_colors.dart';
import '../widgets/protection_toggle.dart';
import '../widgets/emergency_dial_row.dart';
import '../widgets/recent_calls_list.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  static final NativeChannelService _native = NativeChannelService();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context, provider)),
                SliverToBoxAdapter(
                  child: _buildProtectionCard(context, provider),
                ),
                SliverToBoxAdapter(
                  child: _buildEmergencySection(context, provider),
                ),
                SliverToBoxAdapter(child: _buildDemoSection(context, provider)),
                SliverToBoxAdapter(child: _buildRecentCalls(context, provider)),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
            // Alarm banner overlay
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              top: provider.isWarning ? 12 : -120,
              left: 12,
              right: 12,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: provider.isWarning ? 1.0 : 0.0,
                child: _AlarmBanner(
                  assessment: provider.assessment,
                  onDismiss: () => provider.dismissWarning(),
                  onHangUp: () => provider.endCall(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF0052CC)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Safe-Call AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                provider.languageLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            icon: const Icon(
              Icons.settings_rounded,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildProtectionCard(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: provider.protectionEnabled
                ? [const Color(0xFF0D2137), const Color(0xFF0A1628)]
                : [AppColors.surface, AppColors.card],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: provider.protectionEnabled
                ? AppColors.primary.withOpacity(0.4)
                : Colors.white12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: 300.ms,
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: provider.protectionEnabled
                        ? AppColors.accent
                        : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: provider.protectionEnabled
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.6),
                              blurRadius: 8,
                            ),
                          ]
                        : [],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.protectionEnabled
                      ? 'Protection Active'
                      : 'Protection Off',
                  style: TextStyle(
                    color: provider.protectionEnabled
                        ? AppColors.accent
                        : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                ProtectionToggle(
                  value: provider.protectionEnabled,
                  onChanged: (_) => provider.toggleProtection(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              provider.protectionEnabled
                  ? 'AI is monitoring your calls'
                  : 'Enable to protect your calls',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Real-time translation · Phishing detection · Visual ARS',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 100.ms);
  }

  Widget _buildEmergencySection(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const EmergencyDialRow(),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 200.ms);
  }

  Widget _buildDemoSection(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Use Safe-Call',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DemoButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Enable Real\nCall Protection',
                  color: AppColors.danger,
                  subtitle:
                      'Use Samsung/Android call UI with Safe-Call screening',
                  onTap: () async {
                    await _native.openCallScreeningSettings();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DemoButton(
                  icon: Icons.layers_rounded,
                  label: 'Allow Overlay\nTranslation',
                  color: AppColors.accent,
                  subtitle:
                      'Show live phishing warnings and translation over calls',
                  onTap: () async {
                    await _native.requestOverlayPermission();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.settings_suggest_rounded,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Open setup to manage language, microphone, and protection settings',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: Colors.white38),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 300.ms);
  }

  Widget _buildRecentCalls(BuildContext context, AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Calls',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          RecentCallsList(logs: provider.callLogs),
        ],
      ),
    ).animate().slideY(begin: 0.1, duration: 400.ms, delay: 400.ms);
  }
}

class _DemoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _DemoButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  final PhishingAssessment assessment;
  final VoidCallback onDismiss;
  final VoidCallback onHangUp;

  const _AlarmBanner({
    required this.assessment,
    required this.onDismiss,
    required this.onHangUp,
  });

  Color _colorForLevel(int level) {
    switch (level) {
      case 3:
        return AppColors.danger;
      case 2:
        return Colors.orangeAccent;
      case 1:
        return AppColors.accent;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForLevel(assessment.riskLevel);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.12), Colors.black.withOpacity(0.4)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assessment.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    assessment.reason,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  onPressed: onHangUp,
                  child: const Text(
                    'Hang up',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text(
                    'Dismiss',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
