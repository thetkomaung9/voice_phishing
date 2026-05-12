import 'dart:convert';

import 'package:http/http.dart' as http;

class CloudTranslationService {
  static const _apiKey = String.fromEnvironment(
    'GOOGLE_CLOUD_TRANSLATE_API_KEY',
  );
  static final Uri _translateUri = Uri.parse(
    'https://translation.googleapis.com/language/translate/v2',
  );

  bool get isConfigured => _apiKey.isNotEmpty;
  String get apiKey => _apiKey;

  Future<String?> translateText({
    required String text,
    required String targetLanguageCode,
  }) async {
    if (text.trim().isEmpty || !isConfigured) {
      return null;
    }

    final response = await http.post(
      _translateUri.replace(queryParameters: {'key': _apiKey}),
      headers: const {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'q': text,
        'target': targetLanguageCode,
        'format': 'text',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>?;
    final translations = data?['translations'] as List<dynamic>?;
    final first = translations != null && translations.isNotEmpty
        ? translations.first as Map<String, dynamic>
        : null;
    final translatedText = first?['translatedText'] as String?;
    return translatedText?.trim().isEmpty ?? true ? null : translatedText;
  }
}
