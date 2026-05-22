import '../models/phishing_assessment.dart';
import 'realtime_phishing_analyzer.dart';
import 'notification_service.dart';

class CoverAlarmResult {
  final String maskedMessage;
  final bool shouldAlarm;
  final PhishingAssessment assessment;

  CoverAlarmResult({
    required this.maskedMessage,
    required this.shouldAlarm,
    required this.assessment,
  });
}

class SpamPhishingService {
  const SpamPhishingService();

  /// Analyze [message], mask sensitive content and decide whether to alarm.
  CoverAlarmResult coverAndAlarm(String message) {
    final analyzer = RealtimePhishingAnalyzer();
    final assessment = analyzer.analyze(message);

    final masked = _maskSensitive(message);

    final shouldAlarm =
        assessment.alertLevel == 'medium' || assessment.alertLevel == 'high';

    // Fire notification asynchronously if alarm is required.
    if (shouldAlarm) {
      NotificationService().showAlarmNotification(
        'Safe-Call Alert',
        '${assessment.message} — ${assessment.reason}',
      );
    }

    return CoverAlarmResult(
      maskedMessage: masked,
      shouldAlarm: shouldAlarm,
      assessment: assessment,
    );
  }

  String _maskSensitive(String s) {
    var out = s;

    // Mask long digit sequences (card numbers, IDs) but leave last 2 digits visible
    out = out.replaceAllMapped(RegExp(r'\d{4,}'), (m) {
      final digits = m.group(0)!;
      if (digits.length <= 4) return '*' * digits.length;
      final keep = 2;
      final masked =
          '*' * (digits.length - keep) + digits.substring(digits.length - keep);
      return masked;
    });

    // Mask email local part (keep domain)
    out = out.replaceAllMapped(
      RegExp(r'([a-zA-Z0-9._%+-]+)@([a-zA-Z0-9.-]+\.[a-zA-Z]{2,})'),
      (m) {
        final local = m.group(1)!;
        final domain = m.group(2)!;
        final visible = local.length <= 2
            ? '*' * local.length
            : local.substring(0, 1) +
                  '*' * (local.length - 2) +
                  local.substring(local.length - 1);
        return '$visible@$domain';
      },
    );

    // Remove obvious links
    out = out.replaceAll(RegExp(r'https?:\/\/\S+'), '[link removed]');

    // Mask phone-like patterns
    out = out.replaceAllMapped(RegExp(r'(\+?\d[\d\s-]{6,}\d)'), (m) {
      final num = m.group(0)!;
      return num.replaceAll(RegExp(r'\d'), '*');
    });

    return out;
  }
}
