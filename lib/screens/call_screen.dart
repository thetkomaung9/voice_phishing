import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/phishing_warning_overlay.dart';
import '../widgets/ars_menu_widget.dart';
import '../widgets/translation_bubble.dart';
import '../widgets/risk_meter.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildCallHeader(context, provider),
                const SizedBox(height: 8),
                RiskMeter(score: provider.riskScore),
                const SizedBox(height: 16),
                Expanded(
                  child: provider.callState == CallState.ars
                      ? const ARSMenuWidget()
                      : _buildTranslationArea(provider),
                ),
                _buildCallControls(context, provider),
              ],
            ),
          ),
          if (provider.isWarning)
            PhishingWarningOverlay(
              assessment: provider.assessment,
              onDismiss: () => provider.dismissWarning(),
              onEndCall: () {
                provider.endCall();
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCallHeader(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white12),
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white54),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  provider.currentCaller,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI Protection Active',
                      style: TextStyle(color: AppColors.accent, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _CallTimer(),
        ],
      ),
    );
  }

  Widget _buildTranslationArea(AppProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.hearing_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Korean (Detected)',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  provider.transcriptText.isEmpty
                      ? 'Listening...'
                      : provider.transcriptText,
                  style: TextStyle(
                    color: provider.transcriptText.isEmpty
                        ? Colors.white24
                        : Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (provider.translationText.isNotEmpty)
            TranslationBubble(
              text: provider.translationText,
            ).animate().slideY(begin: 0.2, duration: 300.ms),
          const Spacer(),
          if (provider.callState == CallState.active)
            GestureDetector(
              onTap: () => provider.switchToARS(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.dialpad_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Switch to Visual ARS',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCallControls(BuildContext context, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ControlButton(
            icon: Icons.mic_off_rounded,
            label: 'Mute',
            color: Colors.white24,
            onTap: () {},
          ),
          _ControlButton(
            icon: Icons.volume_up_rounded,
            label: 'Speaker',
            color: Colors.white24,
            onTap: () {},
          ),
          GestureDetector(
            onTap: () {
              provider.endCall();
              Navigator.pop(context);
            },
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.call_end_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          _ControlButton(
            icon: Icons.dialpad_rounded,
            label: 'Keypad',
            color: Colors.white24,
            onTap: () {},
          ),
          _ControlButton(
            icon: Icons.add_call,
            label: 'Add',
            color: Colors.white24,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _CallTimer extends StatefulWidget {
  @override
  State<_CallTimer> createState() => _CallTimerState();
}

class _CallTimerState extends State<_CallTimer> {
  late final Stream<int> _stream;

  @override
  void initState() {
    super.initState();
    _stream = Stream.periodic(const Duration(seconds: 1), (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _stream,
      builder: (context, snap) {
        final s = snap.data ?? 0;
        final min = s ~/ 60;
        final sec = s % 60;
        return Text(
          '${min.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontFamily: 'monospace',
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
