import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/protection_toggle.dart';
import '../widgets/emergency_dial_row.dart';
import '../widgets/recent_calls_list.dart';
import 'call_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context, provider)),
            SliverToBoxAdapter(child: _buildProtectionCard(context, provider)),
            SliverToBoxAdapter(
              child: _buildEmergencySection(context, provider),
            ),
            SliverToBoxAdapter(child: _buildDemoSection(context, provider)),
            SliverToBoxAdapter(child: _buildRecentCalls(context, provider)),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
            'Demo Scenarios',
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
                  icon: Icons.warning_amber_rounded,
                  label: 'Phishing\nCall Demo',
                  color: AppColors.danger,
                  onTap: () {
                    provider.simulatePhishingCall();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CallScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DemoButton(
                  icon: Icons.dialpad_rounded,
                  label: 'Bank ARS\nDemo',
                  color: AppColors.accent,
                  onTap: () {
                    provider.simulateARSCall();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CallScreen()),
                    );
                  },
                ),
              ),
            ],
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
  final Color color;
  final VoidCallback onTap;
  const _DemoButton({
    required this.icon,
    required this.label,
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
          ],
        ),
      ),
    );
  }
}
