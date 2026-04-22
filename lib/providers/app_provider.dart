import 'package:flutter/material.dart';

enum CallState { idle, active, warning, ars }

enum Language { burmese, vietnamese, chinese, english }

class CallLog {
  final String id;
  final String callerNumber;
  final DateTime timestamp;
  final double riskScore;
  final String summary;
  final Duration duration;

  CallLog({
    required this.id,
    required this.callerNumber,
    required this.timestamp,
    required this.riskScore,
    required this.summary,
    required this.duration,
  });
}

class AppProvider extends ChangeNotifier {
  bool _protectionEnabled = true;
  Language _selectedLanguage = Language.burmese;
  CallState _callState = CallState.idle;
  double _riskScore = 0.0;
  String _translationText = '';
  bool _isWarning = false;
  List<CallLog> _callLogs = [];
  String _currentCaller = '';

  bool get protectionEnabled => _protectionEnabled;
  Language get selectedLanguage => _selectedLanguage;
  CallState get callState => _callState;
  double get riskScore => _riskScore;
  String get translationText => _translationText;
  bool get isWarning => _isWarning;
  List<CallLog> get callLogs => _callLogs;
  String get currentCaller => _currentCaller;

  String get languageLabel {
    switch (_selectedLanguage) {
      case Language.burmese:
        return 'မြန်မာဘာသာ';
      case Language.vietnamese:
        return 'Tiếng Việt';
      case Language.chinese:
        return '中文';
      case Language.english:
        return 'English';
    }
  }

  void toggleProtection() {
    _protectionEnabled = !_protectionEnabled;
    notifyListeners();
  }

  void setLanguage(Language lang) {
    _selectedLanguage = lang;
    notifyListeners();
  }

  void startCall(String caller) {
    _currentCaller = caller;
    _callState = CallState.active;
    _riskScore = 0.0;
    _isWarning = false;
    _translationText = '';
    notifyListeners();
  }

  void updateTranslation(String text, double risk) {
    _translationText = text;
    _riskScore = risk;
    if (risk > 0.7) {
      _isWarning = true;
      _callState = CallState.warning;
    }
    notifyListeners();
  }

  void switchToARS() {
    _callState = CallState.ars;
    notifyListeners();
  }

  void endCall() {
    _callLogs.insert(
      0,
      CallLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        callerNumber: _currentCaller,
        timestamp: DateTime.now(),
        riskScore: _riskScore,
        summary: _riskScore > 0.7
            ? '⚠️ 보이스피싱 의심 통화가 감지되었습니다.'
            : '안전한 통화로 분석되었습니다.',
        duration: const Duration(minutes: 2, seconds: 34),
      ),
    );
    _callState = CallState.idle;
    _isWarning = false;
    _riskScore = 0.0;
    _translationText = '';
    _currentCaller = '';
    notifyListeners();
  }

  void dismissWarning() {
    _isWarning = false;
    _callState = CallState.active;
    notifyListeners();
  }

  // Demo: simulate incoming call with phishing
  void simulatePhishingCall() {
    startCall('+82-10-XXXX-XXXX');
    Future.delayed(const Duration(seconds: 2), () {
      updateTranslation(
        '안녕하세요, 저는 금융감독원 직원입니다. 귀하의 계좌가 범죄에 연루되어 즉시 계좌 이체가 필요합니다.',
        0.92,
      );
    });
  }

  // Demo: simulate ARS call
  void simulateARSCall() {
    startCall('1588-2100 (KB국민은행)');
    Future.delayed(const Duration(seconds: 1), () {
      _translationText = '안녕하세요, KB국민은행입니다. 원하시는 서비스를 선택해 주세요.';
      _callState = CallState.ars;
      notifyListeners();
    });
  }
}
