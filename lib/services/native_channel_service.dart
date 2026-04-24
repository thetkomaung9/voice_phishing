import 'dart:async';
import 'package:flutter/services.dart';
import '../models/phishing_assessment.dart';

class CallEvent {
  final String transcript;
  final PhishingAssessment assessment;
  final String phoneNumber;

  const CallEvent({
    required this.transcript,
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
        phoneNumber: map['phone_number'] as String? ?? 'Unknown',
        assessment: PhishingAssessment.fromJson(map),
      );
    });
    return _stream!;
  }

  Future<void> startMonitoring(String phoneNumber) =>
      _method.invokeMethod('startMonitoring', {'phoneNumber': phoneNumber});

  Future<void> stopMonitoring() => _method.invokeMethod('stopMonitoring');

  Future<bool> hasOverlayPermission() async =>
      await _method.invokeMethod<bool>('hasOverlayPermission') ?? false;

  Future<void> requestOverlayPermission() =>
      _method.invokeMethod('requestOverlayPermission');

  Future<void> setProtectionEnabled(bool enabled) =>
      _method.invokeMethod('setProtectionEnabled', {'enabled': enabled});

  Future<bool> getProtectionEnabled() async =>
      await _method.invokeMethod<bool>('getProtectionEnabled') ?? true;

  Future<void> setPreferredLanguage(String languageCode) => _method
      .invokeMethod('setPreferredLanguage', {'languageCode': languageCode});

  Future<String> getPreferredLanguage() async =>
      await _method.invokeMethod<String>('getPreferredLanguage') ?? 'en';

  Future<void> openCallScreeningSettings() =>
      _method.invokeMethod('openCallScreeningSettings');

  Future<bool> isCallScreeningEnabled() async =>
      await _method.invokeMethod<bool>('isCallScreeningEnabled') ?? false;

  Future<void> speakTextCallMessage(
    String text, {
    required String languageCode,
  }) => _method.invokeMethod('speakTextCallMessage', {
    'text': text,
    'languageCode': languageCode,
  });

  Future<void> stopTextCallSpeaker() =>
      _method.invokeMethod('stopTextCallSpeaker');
}
