import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/phishing_assessment.dart';

class CallEvent {
  final String transcript;
  final String englishTranslation;
  final String myanmarTranslation;
  final PhishingAssessment assessment;
  final String phoneNumber;

  const CallEvent({
    required this.transcript,
    required this.englishTranslation,
    required this.myanmarTranslation,
    required this.assessment,
    required this.phoneNumber,
  });
}

class NativeChannelService {
  static const _method = MethodChannel('com.safecall.ai/callMonitor');
  static const _event = EventChannel('com.safecall.ai/callEvents');

  Stream<CallEvent>? _stream;

  Stream<CallEvent> get callEvents {
    _stream ??= _event.receiveBroadcastStream().map((raw) {
      final map = Map<String, dynamic>.from(raw as Map);
      return CallEvent(
        transcript: map['transcript'] as String? ?? '',
        englishTranslation: map['english_translation'] as String? ?? '',
        myanmarTranslation: map['myanmar_translation'] as String? ?? '',
        phoneNumber: map['phone_number'] as String? ?? 'Unknown',
        assessment: PhishingAssessment.fromJson(map),
      );
    });
    return _stream!;
  }

  Future<void> startMonitoring(String phoneNumber) {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('startMonitoring', {
      'phoneNumber': phoneNumber,
    });
  }

  Future<void> stopMonitoring() {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('stopMonitoring');
  }

  Future<bool> hasOverlayPermission() async {
    if (kIsWeb) {
      return false;
    }
    return await _method.invokeMethod<bool>('hasOverlayPermission') ?? false;
  }

  Future<void> requestOverlayPermission() {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('requestOverlayPermission');
  }

  Future<void> setProtectionEnabled(bool enabled) {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('setProtectionEnabled', {'enabled': enabled});
  }

  Future<bool> getProtectionEnabled() async {
    if (kIsWeb) {
      return true;
    }
    return await _method.invokeMethod<bool>('getProtectionEnabled') ?? true;
  }

  Future<void> setPreferredLanguage(String languageCode) {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('setPreferredLanguage', {
      'languageCode': languageCode,
    });
  }

  Future<void> setCloudTranslationApiKey(String apiKey) {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('setCloudTranslationApiKey', {
      'apiKey': apiKey,
    });
  }

  Future<String> getPreferredLanguage() async {
    if (kIsWeb) {
      return 'en';
    }
    return await _method.invokeMethod<String>('getPreferredLanguage') ?? 'en';
  }

  Future<void> openCallScreeningSettings() {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('openCallScreeningSettings');
  }

  Future<bool> isCallScreeningEnabled() async {
    if (kIsWeb) {
      return false;
    }
    return await _method.invokeMethod<bool>('isCallScreeningEnabled') ?? false;
  }

  Future<void> openAccessibilitySettings() {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('openAccessibilitySettings');
  }

  Future<bool> isSamsungTextCallCaptureEnabled() async {
    if (kIsWeb) {
      return false;
    }
    return await _method.invokeMethod<bool>(
          'isSamsungTextCallCaptureEnabled',
        ) ??
        false;
  }

  Future<void> speakTextCallMessage(
    String text, {
    required String languageCode,
  }) {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('speakTextCallMessage', {
      'text': text,
      'languageCode': languageCode,
    });
  }

  Future<void> stopTextCallSpeaker() {
    if (kIsWeb) {
      return Future.value();
    }
    return _method.invokeMethod('stopTextCallSpeaker');
  }
}
