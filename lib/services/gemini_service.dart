import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'connectivity_service.dart';
import 'threat_intelligence_db.dart';

/// Result from Gemini AI scam analysis
class GeminiAnalysisResult {
  final String verdict; // SAFE, SUSPICIOUS, SCAM
  final int confidence; // 0-100
  final String riskLevel; // LOW, MEDIUM, HIGH
  final List<String> riskFlags;
  final String explanationEn;
  final String explanationAm;
  final String recommendedAction;

  const GeminiAnalysisResult({
    required this.verdict,
    required this.confidence,
    required this.riskLevel,
    required this.riskFlags,
    required this.explanationEn,
    required this.explanationAm,
    required this.recommendedAction,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return GeminiAnalysisResult(
      verdict: (json['verdict'] as String? ?? 'UNKNOWN').toUpperCase(),
      confidence: (json['confidence'] as num?)?.toInt() ?? 50,
      riskLevel: (json['riskLevel'] as String? ?? 'MEDIUM').toUpperCase(),
      riskFlags: List<String>.from(json['riskFlags'] as List? ?? []),
      explanationEn: json['explanationEn'] as String? ?? '',
      explanationAm: json['explanationAm'] as String? ?? '',
      recommendedAction: json['recommendedAction'] as String? ?? '',
    );
  }

  factory GeminiAnalysisResult.fallback() {
    return const GeminiAnalysisResult(
      verdict: 'UNKNOWN',
      confidence: 50,
      riskLevel: 'MEDIUM',
      riskFlags: ['AI analysis unavailable — using offline detection only'],
      explanationEn: 'AI analysis could not be completed. Offline detection results are shown.',
      explanationAm: 'AI ትንታኔ ሊጠናቀቅ አልቻለም። ከኢንተርኔት ውጪ ያለው ውጤት ይታያል።',
      recommendedAction: 'Use the local risk score with caution.',
    );
  }
}

class GeminiChatMessage {
  final String role; // 'user' or 'model'
  final String text;

  const GeminiChatMessage({required this.role, required this.text});
}

class GeminiService {
  static String get _apiKey => AppConfig.geminiApiKey;

  // Active production models supported by Gemini API
  static const List<String> _models = [
    'gemini-3.5-flash',
    'gemini-3.6-flash',
    'gemini-3.5-flash-lite',
  ];

  static bool get hasValidKey =>
      _apiKey.isNotEmpty && !_apiKey.startsWith('demo-');

  static const String _systemContext = '''
You are a cybersecurity expert AI assistant in "Meketa" (መከታ), an Ethiopian mobile security application.

CRITICAL RESPONSE RULES:
- Keep all answers SHORT, DIRECT, and ACTIONABLE (maximum 2 to 4 bullet points or 2-3 brief sentences).
- Do NOT use excessive or casual emojis. Never use party, fire, laughing, or decorative emojis. At most use standard professional indicators or none at all.
- Give immediate practical guidance:
  * Telebirr: check real balance via *127# or Telebirr SuperApp, official hotline 994.
  * CBE: check balance via *889# or CBE Mobile Banking, official hotline 951.
  * Never share OTP/PIN codes with anyone.
- Fluently support English and Amharic concisely.
- Do not produce conversational filler, lengthy intros, or long lectures.
''';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  /// Multi-turn chat with the Gemini AI security assistant.
  static Future<String> chatWithAssistant(
    List<GeminiChatMessage> history,
    String newMessage,
  ) async {
    if (!hasValidKey) {
      return 'AI service not configured. Please set GEMINI_API_KEY in app configuration.';
    }

    if (!(await ConnectivityService.hasInternet)) {
      return 'No internet connection. AI chat requires connectivity — please reconnect and try again.';
    }

    final contents = <Map<String, dynamic>>[];

    // Filter and sanitize history so roles strictly alternate between 'user' and 'model'
    String? lastRole;
    for (final msg in history) {
      final role = msg.role == 'user' ? 'user' : 'model';
      if (role != lastRole && msg.text.trim().isNotEmpty) {
        contents.add({
          'role': role,
          'parts': [
            {'text': msg.text}
          ]
        });
        lastRole = role;
      }
    }

    // Add current user prompt
    contents.add({
      'role': 'user',
      'parts': [
        {'text': newMessage}
      ]
    });

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemContext}
        ]
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.2,
        'maxOutputTokens': 350,
      },
    });

    for (final model in _models) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';
        final response = await http
            .post(
              Uri.parse(url),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = _extractText(data);
          if (text.isNotEmpty) return text;
        }
      } catch (e) {
        debugPrint('[GeminiService] Model $model chat error: $e');
      }
    }

    return 'Could not retrieve AI response. Please check connection and try again.';
  }

  /// Analyze an SMS message for scam indicators using Gemini AI with local 7-day TTL caching and privacy guard.
  static Future<GeminiAnalysisResult> analyzeMessage(
    String message,
    String sender, {
    List<String> localFlags = const [],
    int localConfidence = 50,
    bool allowCloudAnalysis = true,
  }) async {
    // 1. Strict Privacy Enforcement: if cloud analysis is disabled, do not transmit text
    if (!allowCloudAnalysis) {
      debugPrint('[GeminiService] Privacy guard: cloud analysis is disabled by user.');
      return GeminiAnalysisResult.fallback();
    }

    if (!hasValidKey) {
      return GeminiAnalysisResult.fallback();
    }

    // 2. Check on-device hash cache (7-day TTL) to avoid redundant API calls
    final cached = await ThreatIntelligenceDb.getCachedAiResult(sender, message);
    if (cached != null) {
      debugPrint('[GeminiService] Using fresh cached AI result for $sender');
      return GeminiAnalysisResult(
        verdict: cached.verdict,
        confidence: cached.confidence,
        riskLevel: cached.riskLevel,
        riskFlags: cached.riskFlags,
        explanationEn: cached.explanationEn,
        explanationAm: cached.explanationAm,
        recommendedAction: cached.recommendedAction,
      );
    }

    if (!(await ConnectivityService.hasInternet)) {
      debugPrint('[GeminiService] Offline — skipping AI second-opinion call');
      return GeminiAnalysisResult.fallback();
    }

    final prompt = '''
Analyze the following Ethiopian SMS message for scam indicators.

SENDER: "$sender"
MESSAGE: "$message"
LOCAL DETECTOR FLAGS: ${localFlags.isEmpty ? 'none' : localFlags.join(', ')}
LOCAL CONFIDENCE: $localConfidence%

Respond ONLY with a valid JSON object in this exact format:
{
  "verdict": "SAFE" | "SUSPICIOUS" | "SCAM",
  "confidence": <integer 0-100>,
  "riskLevel": "LOW" | "MEDIUM" | "HIGH",
  "riskFlags": ["flag1", "flag2"],
  "explanationEn": "<1-2 sentence plain English explanation>",
  "explanationAm": "<1-2 sentence plain Amharic explanation>",
  "recommendedAction": "<what the user should do>"
}
''';

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemContext}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 512,
      },
    });

    for (final model in _models) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';
        final response = await http
            .post(
              Uri.parse(url),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = _extractText(data);
          if (text.isNotEmpty) {
            final parsedResult = _parseAnalysisResult(text);

            // Save to local cache with 7-day expiration
            await ThreatIntelligenceDb.saveAiResult(
              sender,
              message,
              CachedAiResult(
                verdict: parsedResult.verdict,
                confidence: parsedResult.confidence,
                riskLevel: parsedResult.riskLevel,
                riskFlags: parsedResult.riskFlags,
                explanationEn: parsedResult.explanationEn,
                explanationAm: parsedResult.explanationAm,
                recommendedAction: parsedResult.recommendedAction,
                cachedAt: DateTime.now(),
              ),
            );

            return parsedResult;
          }
        }
      } catch (e) {
        debugPrint('[GeminiService] analyzeMessage model $model error: $e');
      }
    }

    return GeminiAnalysisResult.fallback();
  }

  /// Explain a scam alert in simple plain language.
  static Future<String> explainAlert({
    required String message,
    required String sender,
    required List<String> detectedFlags,
    required int confidence,
    required String language,
    bool allowCloudAnalysis = true,
  }) async {
    final isAmharic = language == 'Amharic';

    if (!allowCloudAnalysis) {
      return isAmharic
          ? 'የክላውድ AI አገልግሎት በመቼት ተዘግቷል።'
          : 'Cloud AI is disabled in settings.';
    }

    if (!hasValidKey) {
      return isAmharic
          ? 'AI አልተዋጋም። እባክዎ መልዕክቱን በራስዎ ይመልከቱ።'
          : 'AI service unavailable. Please review the message carefully using the detected flags above.';
    }

    if (!(await ConnectivityService.hasInternet)) {
      return isAmharic
          ? 'የኢንተርኔት ግንኙነት የለም። AI ማብራሪያ የሚያስፈልግ ነው።'
          : 'No internet connection. AI explanation requires connectivity.';
    }

    final prompt = isAmharic
        ? '''
የሚከተለውን አጠራጣሪ የኢትዮጵያ SMS መልዕክት በአጭር እና ግልጽ ቋንቋ ለተጠቃሚው አብራራ:
ላኪ: "$sender"
መልዕክት: "$message"
የተገኙ ምልክቶች: ${detectedFlags.join(', ')}
የማጭበርበር ዕድል: $confidence%

ተጠቃሚው ምን ጥንቃቄ ማድረግ እንዳለበት በ2-3 ዓረፍተ-ነገር በአማርኛ አስረዳ።
'''
        : '''
Explain the following suspicious Ethiopian SMS message in plain, easy-to-understand language:
SENDER: "$sender"
MESSAGE: "$message"
DETECTED FLAGS: ${detectedFlags.join(', ')}
SCAM PROBABILITY: $confidence%

Explain why this is dangerous and what the user must do in 2-3 concise sentences.
''';

    final body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': _systemContext}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
        'maxOutputTokens': 300,
      },
    });

    for (final model in _models) {
      try {
        final url = 'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey';
        final response = await http
            .post(
              Uri.parse(url),
              headers: _headers,
              body: body,
            )
            .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final text = _extractText(data);
          if (text.isNotEmpty) return text;
        }
      } catch (e) {
        debugPrint('[GeminiService] explainAlert model $model error: $e');
      }
    }

    return isAmharic
        ? 'ማብራሪያውን ማግኘት አልተቻለም። እባክዎ ጥንቃቄ ያድርጉ።'
        : 'Could not generate explanation. Please treat this message with caution.';
  }

  // --- Helper methods ---

  static String _extractText(Map<String, dynamic> responseData) {
    try {
      final candidates = responseData['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return '';

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      if (content == null) return '';

      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return '';

      return (parts[0]['text'] as String? ?? '').trim();
    } catch (e) {
      debugPrint('[GeminiService] Text extraction error: $e');
      return '';
    }
  }

  static GeminiAnalysisResult _parseAnalysisResult(String rawText) {
    try {
      var cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) {
        cleaned = cleaned.substring(7);
      } else if (cleaned.startsWith('```')) {
        cleaned = cleaned.substring(3);
      }
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
      cleaned = cleaned.trim();

      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return GeminiAnalysisResult.fromJson(json);
    } catch (e) {
      debugPrint('[GeminiService] Parse error: $e');
      return GeminiAnalysisResult.fallback();
    }
  }
}
