import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/phishing_assessment.dart';
import '../theme/app_colors.dart';

class PhishingWarningOverlay extends StatelessWidget {
  final PhishingAssessment assessment;
  final VoidCallback onDismiss;
  final VoidCallback onEndCall;
  const PhishingWarningOverlay({
    super.key,
    required this.assessment,
    required this.onDismiss,
    required this.onEndCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child:
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A0A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.danger, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.3),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.danger.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.warning_rounded,
                            color: AppColors.danger,
                            size: 44,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 600.ms,
                        ),
                    const SizedBox(height: 20),
                    const Text(
                      'VOICE PHISHING ALERT',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      assessment.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.danger,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Risk Score: ${(assessment.score * 100).round()}%',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      assessment.reason,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onEndCall,
                        icon: const Icon(Icons.call_end_rounded),
                        label: const Text(
                          'Hang Up Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: onDismiss,
                      child: const Text(
                        'Dismiss Warning',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 300.ms,
                curve: Curves.easeOut,
              ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
