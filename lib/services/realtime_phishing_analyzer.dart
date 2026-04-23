import '../models/phishing_assessment.dart';

class RealtimePhishingAnalyzer {
  const RealtimePhishingAnalyzer();

  static const String systemPrompt = '''
You are an advanced real-time AI assistant for a mobile application called "Safe-Call AI".

Your primary role is to monitor live phone call transcripts and determine whether the conversation is SAFE or a VOICE PHISHING attempt.

You will receive continuous speech-to-text (STT) transcripts in real-time. The text may be partial, incomplete, or evolving. You must continuously analyze the context and update your risk assessment instantly.

------------------------
🎯 OBJECTIVE
------------------------
Detect potential voice phishing attempts as early as possible and protect the user by issuing timely warnings.

------------------------
🧠 ANALYSIS CRITERIA
------------------------
Evaluate the conversation based on these indicators:

1. Personal/Financial Data Requests:
- OTP, verification codes
- Bank account, card numbers
- ID/passport numbers

2. Urgency & Pressure:
- "Act now", "urgent", "your account will be blocked"
- Threats or fear tactics

3. Impersonation:
- Bank staff, police, government officer, delivery service
- Fake authority claims

4. Suspicious Actions:
- Asking to transfer money
- Asking to install apps or click links
- Requesting remote access

5. Language Patterns:
- Repetitive scripts
- Unnatural or scripted conversation tone

6. Multi-language Context:
- The call may be in Korean, English, Burmese, or Vietnamese
- Internally understand and analyze regardless of language

------------------------
⚠️ RISK LEVEL DEFINITION
------------------------
0 = SAFE (No suspicious behavior)
1 = SUSPICIOUS (Some unusual signals, uncertain)
2 = WARNING (Clear risk indicators present)
3 = DANGEROUS (Strong evidence of voice phishing)

Always prioritize user safety. If uncertain, choose a higher risk level.

------------------------
📤 OUTPUT FORMAT (STRICT JSON ONLY)
------------------------
Return ONLY this JSON structure:

{
  "risk_level": 0-3,
  "is_phishing": true/false,
  "alert_level": "none | low | medium | high",
  "message": "short user-facing warning message",
  "reason": "brief explanation of detected pattern",
  "recommended_action": "continue | be careful | hang up immediately"
}

------------------------
⚡ REAL-TIME BEHAVIOR RULES
------------------------
- Continuously update risk level as new transcript arrives
- Do NOT wait for full conversation
- Escalate immediately if strong phishing signals appear
- Keep responses short and fast (low latency)
- Do NOT include unnecessary explanation

------------------------
📱 USER MESSAGE GUIDELINES
------------------------
- SAFE → "No risk detected"
- SUSPICIOUS → "This call seems unusual. Be careful."
- WARNING → "This call may be a scam. Do not share personal info."
- DANGEROUS → "Possible scam! Hang up immediately!"

------------------------
🚫 RESTRICTIONS
------------------------
- Do NOT output anything except JSON
- Do NOT explain outside the JSON
- Do NOT delay response
''';

  PhishingAssessment analyze(String transcript) {
    final normalized = transcript.toLowerCase();
    if (normalized.trim().isEmpty) {
      return const PhishingAssessment.safe();
    }

    final indicators = <String>[];
    var score = 0;

    if (_matchesAny(normalized, const [
      'otp',
      'verification code',
      'security code',
      'account number',
      'card number',
      'passport',
      'resident number',
      '주민등록',
      '인증번호',
      '계좌번호',
      '카드번호',
      'otp 번호',
    ])) {
      score += 3;
      indicators.add('requesting personal or financial data');
    }

    if (_matchesAny(normalized, const [
      'urgent',
      'immediately',
      'right now',
      'blocked',
      'frozen',
      'suspended',
      'act now',
      '지금',
      '즉시',
      '정지',
      '차단',
    ])) {
      score += 2;
      indicators.add('using urgency or pressure');
    }

    if (_matchesAny(normalized, const [
      'bank',
      'financial supervisory service',
      'police',
      'prosecutor',
      'government',
      'delivery service',
      '금융감독원',
      '검찰',
      '경찰',
      '은행',
      '택배',
    ])) {
      score += 2;
      indicators.add('impersonating an authority');
    }

    if (_matchesAny(normalized, const [
      'transfer money',
      'send money',
      'wire money',
      'install this app',
      'click this link',
      'remote access',
      '원격',
      '송금',
      '이체',
      '앱 설치',
      '링크',
    ])) {
      score += 3;
      indicators.add('requesting suspicious actions');
    }

    if (_looksScripted(normalized)) {
      score += 1;
      indicators.add('scripted or repetitive tone');
    }

    if (score >= 7) {
      return PhishingAssessment(
        riskLevel: 3,
        isPhishing: true,
        alertLevel: 'high',
        message: 'Possible scam! Hang up immediately!',
        reason: _joinReasons(indicators, fallback: 'Multiple phishing signals detected'),
        recommendedAction: 'hang up immediately',
      );
    }

    if (score >= 4) {
      return PhishingAssessment(
        riskLevel: 2,
        isPhishing: true,
        alertLevel: 'medium',
        message: 'This call may be a scam. Do not share personal info.',
        reason: _joinReasons(indicators, fallback: 'Clear scam indicators detected'),
        recommendedAction: 'be careful',
      );
    }

    if (score >= 2) {
      return PhishingAssessment(
        riskLevel: 1,
        isPhishing: false,
        alertLevel: 'low',
        message: 'This call seems unusual. Be careful.',
        reason: _joinReasons(indicators, fallback: 'Some suspicious patterns detected'),
        recommendedAction: 'be careful',
      );
    }

    return const PhishingAssessment.safe();
  }

  bool _matchesAny(String text, List<String> patterns) {
    for (final pattern in patterns) {
      if (text.contains(pattern)) {
        return true;
      }
    }
    return false;
  }

  bool _looksScripted(String text) {
    final scriptedMarkers = <String>[
      'for your safety',
      'this is an official notice',
      'your account is involved in a crime',
      '귀하의 계좌가 범죄에 연루',
    ];

    final repeatedWords = text.split(' ').where((word) => word.isNotEmpty).toList();
    final uniqueRatio = repeatedWords.isEmpty
        ? 1.0
        : repeatedWords.toSet().length / repeatedWords.length;

    return _matchesAny(text, scriptedMarkers) || uniqueRatio < 0.6;
  }

  String _joinReasons(List<String> indicators, {required String fallback}) {
    if (indicators.isEmpty) {
      return fallback;
    }
    return indicators.take(2).join(' and ');
  }
}
