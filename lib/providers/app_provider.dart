import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/phishing_assessment.dart';
import '../services/cloud_translation_service.dart';
import '../services/firebase_database_service.dart';
import '../services/native_channel_service.dart';
import '../services/realtime_phishing_analyzer.dart';

enum CallState { idle, active, warning, ars, textCall }

enum Language { burmese, vietnamese, chinese, english }

enum TextCallSpeaker { assistant, caller, user }

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'caller_number': callerNumber,
    'timestamp': timestamp.toIso8601String(),
    'timestamp_ms': timestamp.millisecondsSinceEpoch,
    'risk_score': riskScore,
    'summary': summary,
    'duration_seconds': duration.inSeconds,
  };

  factory CallLog.fromJson(Map<String, dynamic> json) {
    final timestampMs = json['timestamp_ms'] as num?;
    final timestampIso = json['timestamp'] as String?;

    return CallLog(
      id: json['id'] as String? ?? '',
      callerNumber: json['caller_number'] as String? ?? 'Unknown',
      timestamp: timestampMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs.toInt())
          : DateTime.tryParse(timestampIso ?? '') ?? DateTime.now(),
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      summary: json['summary'] as String? ?? 'No summary available',
      duration: Duration(seconds: json['duration_seconds'] as int? ?? 0),
    );
  }
}

class TextCallMessage {
  final String id;
  final TextCallSpeaker speaker;
  final String text;
  final String englishText;
  final String myanmarText;
  final DateTime timestamp;

  const TextCallMessage({
    required this.id,
    required this.speaker,
    required this.text,
    this.englishText = '',
    this.myanmarText = '',
    required this.timestamp,
  });
}

class AppProvider extends ChangeNotifier {
  final RealtimePhishingAnalyzer _analyzer = const RealtimePhishingAnalyzer();
  final CloudTranslationService _translation = CloudTranslationService();
  final NativeChannelService _native = NativeChannelService();
  final FirebaseDatabaseService _database = FirebaseDatabaseService();
  StreamSubscription<CallEvent>? _nativeSub;
  StreamSubscription<List<Map<String, dynamic>>>? _callLogsSub;
  final List<Timer> _demoTimers = [];
  final List<TextCallMessage> _textCallMessages = [];
  final List<String> _quickTextCallReplies = const [
    'Please tell me why you are calling.',
    'Please wait. I am reading this by text.',
    'I do not share OTP or bank account numbers.',
    'Please send an official text message instead.',
    'I will hang up and call the company back directly.',
  ];
  int _translationRequestId = 0;
  bool _protectionEnabled = true;
  Language _selectedLanguage = Language.burmese;
  CallState _callState = CallState.idle;
  double _riskScore = 0.0;
  String _translationText = '';
  String _englishTranslationText = '';
  String _myanmarTranslationText = '';
  String _transcriptText = '';
  bool _isWarning = false;
  final List<CallLog> _callLogs = [];
  String _currentCaller = '';
  PhishingAssessment _assessment = const PhishingAssessment.safe();
  CallState _stateBeforeWarning = CallState.active;
  String _lastTextCallMessage = '';
  TextCallSpeaker? _lastTextCallSpeaker;

  bool get protectionEnabled => _protectionEnabled;
  Language get selectedLanguage => _selectedLanguage;
  CallState get callState => _callState;
  bool get isTextCallActive => _callState == CallState.textCall;
  double get riskScore => _riskScore;
  String get translationText => _translationText;
  String get englishTranslationText => _englishTranslationText;
  String get myanmarTranslationText => _myanmarTranslationText;
  String get transcriptText => _transcriptText;
  bool get isWarning => _isWarning;
  List<CallLog> get callLogs => _callLogs;
  String get currentCaller => _currentCaller;
  PhishingAssessment get assessment => _assessment;
  List<TextCallMessage> get textCallMessages => _textCallMessages;
  List<String> get quickTextCallReplies => _quickTextCallReplies;

  AppProvider() {
    unawaited(_loadNativeSettings());
    _callLogsSub = _database.watchCallLogs().listen((items) {
      _callLogs
        ..clear()
        ..addAll(items.map(CallLog.fromJson));
      notifyListeners();
    }, onError: (_) {});
  }

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
    unawaited(_native.setProtectionEnabled(_protectionEnabled));
    notifyListeners();
  }

  void setLanguage(Language lang) {
    _selectedLanguage = lang;
    unawaited(_native.setPreferredLanguage(lang.nativeLanguageCode));
    notifyListeners();
  }

  Future<void> startCall(String caller) async {
    _clearDemoTimers();
    _translationRequestId++;
    _currentCaller = caller;
    _callState = CallState.active;
    _riskScore = 0.0;
    _isWarning = false;
    _translationText = '';
    _englishTranslationText = '';
    _myanmarTranslationText = '';
    _transcriptText = '';
    _assessment = const PhishingAssessment.safe();
    _textCallMessages.clear();
    _lastTextCallMessage = '';
    _lastTextCallSpeaker = null;
    notifyListeners();

    _native.startMonitoring(caller).catchError((_) {});
    final micGranted = await Permission.microphone.isGranted;
    if (micGranted) {
      _nativeSub = _native.callEvents.listen((event) {
        unawaited(
          processTranscript(
            event.transcript,
            englishTranslation: event.englishTranslation,
            myanmarTranslation: event.myanmarTranslation,
          ),
        );
      });
    }
  }

  Future<void> processTranscript(
    String transcript, {
    String? translatedText,
    String? englishTranslation,
    String? myanmarTranslation,
  }) async {
    final requestId = ++_translationRequestId;
    _transcriptText = transcript;
    _englishTranslationText = (englishTranslation?.trim().isNotEmpty ?? false)
        ? englishTranslation!.trim()
        : (translatedText?.trim() ?? '');
    _myanmarTranslationText = (myanmarTranslation?.trim().isNotEmpty ?? false)
        ? myanmarTranslation!.trim()
        : '';
    _translationText = _translationForSelectedLanguage(
      fallback: translatedText ?? transcript,
    );
    _assessment = _analyzer.analyze(transcript);
    _riskScore = _assessment.score;

    if (_assessment.riskLevel >= 2) {
      _isWarning = true;
      if (_callState != CallState.warning) {
        _stateBeforeWarning = _callState;
      }
      _callState = CallState.warning;
    } else if (_callState != CallState.ars &&
        _callState != CallState.textCall) {
      _callState = CallState.active;
    }

    if (_callState == CallState.textCall) {
      _appendTextCallMessage(
        speaker: TextCallSpeaker.caller,
        text: transcript,
        englishText: _englishTranslationText,
        myanmarText: _myanmarTranslationText,
      );
    }
    notifyListeners();

    if (transcript.trim().isEmpty) {
      return;
    }

    final needsEnglish =
        _englishTranslationText.isEmpty &&
        _selectedLanguage != Language.english &&
        translatedText == null;
    final translations = await Future.wait<String?>([
      if (needsEnglish)
        _translation.translateText(
          text: transcript,
          targetLanguageCode: Language.english.cloudLanguageCode,
        )
      else
        Future<String?>.value(null),
      if (_myanmarTranslationText.isEmpty || translatedText != null)
        _translation.translateText(
          text: transcript,
          targetLanguageCode: Language.burmese.cloudLanguageCode,
        )
      else
        Future<String?>.value(null),
      if (translatedText == null)
        _translation.translateText(
          text: transcript,
          targetLanguageCode: _selectedLanguage.cloudLanguageCode,
        )
      else
        Future<String?>.value(translatedText),
    ]);

    if (requestId != _translationRequestId) {
      return;
    }

    final english = translations[0];
    final myanmar = translations[1];
    final selected = translations[2];
    if (english?.trim().isNotEmpty ?? false) {
      _englishTranslationText = english!.trim();
    }
    if (myanmar?.trim().isNotEmpty ?? false) {
      _myanmarTranslationText = myanmar!.trim();
    }
    if (selected?.trim().isNotEmpty ?? false) {
      _translationText = selected!.trim();
      if (_selectedLanguage == Language.english) {
        _englishTranslationText = _translationText;
      }
    } else {
      _translationText = _translationForSelectedLanguage(fallback: transcript);
    }
    if (_callState == CallState.textCall) {
      _appendTextCallMessage(
        speaker: TextCallSpeaker.caller,
        text: transcript,
        englishText: _englishTranslationText,
        myanmarText: _myanmarTranslationText,
      );
    }
    notifyListeners();
  }

  void switchToArs() {
    _callState = CallState.ars;
    notifyListeners();
  }

  void switchToTextCall() {
    if (_callState == CallState.textCall) {
      return;
    }

    _callState = CallState.textCall;
    _appendTextCallMessage(
      speaker: TextCallSpeaker.assistant,
      text:
          'Text Call is on. Type a reply and Safe-Call will read it to the caller.',
    );

    final latestCallerText = _translationText.isNotEmpty
        ? _translationText
        : _transcriptText;
    if (latestCallerText.isNotEmpty) {
      _appendTextCallMessage(
        speaker: TextCallSpeaker.caller,
        text: _transcriptText,
        englishText: _englishTranslationText,
        myanmarText: _myanmarTranslationText,
      );
    }

    notifyListeners();
  }

  Future<void> sendTextCallMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _appendTextCallMessage(speaker: TextCallSpeaker.user, text: trimmed);
    notifyListeners();

    try {
      await _native.speakTextCallMessage(
        trimmed,
        languageCode: _selectedLanguage.nativeLanguageCode,
      );
    } catch (_) {}
  }

  void endCall() {
    _clearDemoTimers();
    final callLog = CallLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      callerNumber: _currentCaller,
      timestamp: DateTime.now(),
      riskScore: _riskScore,
      summary: _assessment.message,
      duration: const Duration(minutes: 2, seconds: 34),
    );
    _callLogs.insert(0, callLog);
    _callState = CallState.idle;
    _translationRequestId++;
    _isWarning = false;
    _riskScore = 0.0;
    _translationText = '';
    _englishTranslationText = '';
    _myanmarTranslationText = '';
    _transcriptText = '';
    _currentCaller = '';
    _assessment = const PhishingAssessment.safe();
    _textCallMessages.clear();
    _lastTextCallMessage = '';
    _lastTextCallSpeaker = null;
    notifyListeners();

    _nativeSub?.cancel();
    _nativeSub = null;
    _native.stopMonitoring();
    _native.stopTextCallSpeaker().catchError((_) {});

    unawaited(
      _database
          .saveCallLog(id: callLog.id, data: callLog.toJson())
          .catchError((_) {}),
    );
  }

  void dismissWarning() {
    _isWarning = false;
    if (_currentCaller.isNotEmpty) {
      _callState = _stateBeforeWarning;
    }
    notifyListeners();
  }

  // Demo: simulate incoming call with phishing
  void simulatePhishingCall() {
    startCall('+82-10-XXXX-XXXX');
    _playDemoScript([
      _DemoLine(
        delay: const Duration(seconds: 2),
        transcript: '안녕하세요, 금융감독원입니다. 본인 확인을 위해 통화를 계속하겠습니다.',
        translation:
            'Hello, this is the Financial Supervisory Service. We will continue this call for identity verification.',
      ),
      _DemoLine(
        delay: const Duration(seconds: 5),
        transcript: '귀하의 계좌가 범죄에 연루되었습니다. 지금 바로 확인하지 않으면 계좌가 정지됩니다.',
        translation:
            'Your bank account is linked to a crime. If you do not verify it right now, your account will be blocked.',
      ),
      _DemoLine(
        delay: const Duration(seconds: 8),
        transcript: '안전을 위해 OTP 번호와 계좌번호를 알려주시고 즉시 안전 계좌로 이체해 주세요.',
        translation:
            'For your safety, tell me your OTP and account number and transfer the money to a safe account immediately.',
      ),
    ]);
  }

  // Demo: simulate ARS call
  void simulateARSCall() {
    startCall('1588-2100 (KB국민은행)');
    _playDemoScript([
      _DemoLine(
        delay: const Duration(seconds: 1),
        transcript: '안녕하세요, KB국민은행입니다. 원하시는 서비스를 선택해 주세요.',
        translation:
            'Hello, this is KB Kookmin Bank. Please choose the service you want.',
        state: CallState.ars,
      ),
    ]);
  }

  void _playDemoScript(List<_DemoLine> lines) {
    for (final line in lines) {
      _demoTimers.add(
        Timer(line.delay, () {
          unawaited(
            processTranscript(
              line.transcript,
              translatedText: line.translation,
            ),
          );
          if (line.state != null) {
            _callState = line.state!;
            notifyListeners();
          }
        }),
      );
    }
  }

  void _clearDemoTimers() {
    for (final timer in _demoTimers) {
      timer.cancel();
    }
    _demoTimers.clear();
  }

  void _appendTextCallMessage({
    required TextCallSpeaker speaker,
    required String text,
    String englishText = '',
    String myanmarText = '',
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (_lastTextCallMessage == trimmed && _lastTextCallSpeaker == speaker) {
      if (_textCallMessages.isNotEmpty &&
          (englishText.trim().isNotEmpty || myanmarText.trim().isNotEmpty)) {
        final last = _textCallMessages.last;
        _textCallMessages[_textCallMessages.length - 1] = TextCallMessage(
          id: last.id,
          speaker: last.speaker,
          text: last.text,
          englishText: englishText.trim().isNotEmpty
              ? englishText.trim()
              : last.englishText,
          myanmarText: myanmarText.trim().isNotEmpty
              ? myanmarText.trim()
              : last.myanmarText,
          timestamp: last.timestamp,
        );
      }
      return;
    }

    _lastTextCallMessage = trimmed;
    _lastTextCallSpeaker = speaker;
    _textCallMessages.add(
      TextCallMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        speaker: speaker,
        text: trimmed,
        englishText: englishText.trim(),
        myanmarText: myanmarText.trim(),
        timestamp: DateTime.now(),
      ),
    );
  }

  String _translationForSelectedLanguage({required String fallback}) {
    switch (_selectedLanguage) {
      case Language.burmese:
        return _myanmarTranslationText.isNotEmpty
            ? _myanmarTranslationText
            : fallback;
      case Language.english:
        return _englishTranslationText.isNotEmpty
            ? _englishTranslationText
            : fallback;
      case Language.vietnamese:
      case Language.chinese:
        return fallback;
    }
  }

  @override
  void dispose() {
    _nativeSub?.cancel();
    _callLogsSub?.cancel();
    _clearDemoTimers();
    super.dispose();
  }

  Future<void> _loadNativeSettings() async {
    try {
      _protectionEnabled = await _native.getProtectionEnabled();
      _selectedLanguage = languageFromNativeLanguageCode(
        await _native.getPreferredLanguage(),
      );
      notifyListeners();
    } on MissingPluginException {
      // Widget tests run without platform channels.
    } catch (_) {
      // Keep in-memory defaults if native settings are unavailable.
    }
  }
}

extension LanguageCodes on Language {
  String get nativeLanguageCode {
    switch (this) {
      case Language.burmese:
        return 'my';
      case Language.vietnamese:
        return 'vi';
      case Language.chinese:
        return 'zh';
      case Language.english:
        return 'en';
    }
  }

  String get cloudLanguageCode {
    switch (this) {
      case Language.burmese:
        return 'my';
      case Language.vietnamese:
        return 'vi';
      case Language.chinese:
        return 'zh-CN';
      case Language.english:
        return 'en';
    }
  }
}

Language languageFromNativeLanguageCode(String code) {
  switch (code) {
    case 'my':
      return Language.burmese;
    case 'vi':
      return Language.vietnamese;
    case 'zh':
    case 'zh-CN':
      return Language.chinese;
    default:
      return Language.english;
  }
}

class _DemoLine {
  final Duration delay;
  final String transcript;
  final String translation;
  final CallState? state;

  const _DemoLine({
    required this.delay,
    required this.transcript,
    required this.translation,
    this.state,
  });
}
