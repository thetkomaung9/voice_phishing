class PhishingAssessment {
  final int riskLevel;
  final bool isPhishing;
  final String alertLevel;
  final String message;
  final String reason;
  final String recommendedAction;

  const PhishingAssessment({
    required this.riskLevel,
    required this.isPhishing,
    required this.alertLevel,
    required this.message,
    required this.reason,
    required this.recommendedAction,
  });

  const PhishingAssessment.safe()
    : riskLevel = 0,
      isPhishing = false,
      alertLevel = 'none',
      message = 'No risk detected',
      reason = 'No suspicious behavior detected',
      recommendedAction = 'continue';

  double get score {
    switch (riskLevel) {
      case 1:
        return 0.4;
      case 2:
        return 0.75;
      case 3:
        return 1.0;
      default:
        return 0.1;
    }
  }

  Map<String, dynamic> toJson() => {
    'risk_level': riskLevel,
    'is_phishing': isPhishing,
    'alert_level': alertLevel,
    'message': message,
    'reason': reason,
    'recommended_action': recommendedAction,
  };

  factory PhishingAssessment.fromJson(Map<String, dynamic> json) {
    return PhishingAssessment(
      riskLevel: json['risk_level'] as int? ?? 0,
      isPhishing: json['is_phishing'] as bool? ?? false,
      alertLevel: json['alert_level'] as String? ?? 'none',
      message: json['message'] as String? ?? 'No risk detected',
      reason: json['reason'] as String? ?? 'No suspicious behavior detected',
      recommendedAction: json['recommended_action'] as String? ?? 'continue',
    );
  }
}
