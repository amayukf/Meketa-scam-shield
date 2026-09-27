import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local community intelligence item representing reported fraud vectors or reputation records
class ThreatIntelligenceRecord {
  final String identifier; // Phone number (e.g. 0911...), domain (e.g. telebirr-gift.xyz), or USSD pattern
  final String type; // 'phone', 'domain', 'ussd', 'pattern'
  final int reportsCount;
  final int riskWeight; // +15 to +40
  final String category; // 'impersonation', 'phishing', 'fake_lottery', 'ussd_trap'
  final String description;
  final DateTime reportedAt;

  const ThreatIntelligenceRecord({
    required this.identifier,
    required this.type,
    required this.reportsCount,
    required this.riskWeight,
    required this.category,
    required this.description,
    required this.reportedAt,
  });
}

/// Cached AI analysis with version and time-to-live (TTL)
class CachedAiResult {
  final String verdict;
  final int confidence;
  final String riskLevel;
  final List<String> riskFlags;
  final String explanationEn;
  final String explanationAm;
  final String recommendedAction;
  final DateTime cachedAt;
  final String schemaVersion;

  const CachedAiResult({
    required this.verdict,
    required this.confidence,
    required this.riskLevel,
    required this.riskFlags,
    required this.explanationEn,
    required this.explanationAm,
    required this.recommendedAction,
    required this.cachedAt,
    this.schemaVersion = 'v1.0',
  });

  bool get isExpired {
    // Expire after 7 days to prevent trusting stale classifications indefinitely
    return DateTime.now().difference(cachedAt).inDays > 7;
  }

  Map<String, dynamic> toJson() => {
        'verdict': verdict,
        'confidence': confidence,
        'riskLevel': riskLevel,
        'riskFlags': riskFlags,
        'explanationEn': explanationEn,
        'explanationAm': explanationAm,
        'recommendedAction': recommendedAction,
        'cachedAt': cachedAt.toIso8601String(),
        'schemaVersion': schemaVersion,
      };

  factory CachedAiResult.fromJson(Map<String, dynamic> json) => CachedAiResult(
        verdict: json['verdict'] as String? ?? 'UNKNOWN',
        confidence: (json['confidence'] as num?)?.toInt() ?? 50,
        riskLevel: json['riskLevel'] as String? ?? 'MEDIUM',
        riskFlags: List<String>.from(json['riskFlags'] as List? ?? []),
        explanationEn: json['explanationEn'] as String? ?? '',
        explanationAm: json['explanationAm'] as String? ?? '',
        recommendedAction: json['recommendedAction'] as String? ?? '',
        cachedAt: DateTime.tryParse(json['cachedAt']?.toString() ?? '') ?? DateTime.now(),
        schemaVersion: json['schemaVersion'] as String? ?? 'v1.0',
      );
}

/// Local on-device repository managing community threat reputation, user feedback adjustments, and AI caching
class ThreatIntelligenceDb {
  static const String _aiCachePrefix = 'ai_cache_';
  static const String _userFeedbackPrefix = 'feedback_';

  // Seeded Ethiopian community threat intelligence (offline reputation database)
  static final Map<String, ThreatIntelligenceRecord> _communityThreats = {
    // Known reported impersonation numbers in Ethiopia
    '251911009988': ThreatIntelligenceRecord(
      identifier: '251911009988',
      type: 'phone',
      reportsCount: 42,
      riskWeight: 35,
      category: 'impersonation',
      description: 'Reported fake Telebirr transfer SMS sender',
      reportedAt: DateTime(2026, 7, 10),
    ),
    '0911009988': ThreatIntelligenceRecord(
      identifier: '0911009988',
      type: 'phone',
      reportsCount: 42,
      riskWeight: 35,
      category: 'impersonation',
      description: 'Reported fake Telebirr transfer SMS sender',
      reportedAt: DateTime(2026, 7, 10),
    ),
    '0988776655': ThreatIntelligenceRecord(
      identifier: '0988776655',
      type: 'phone',
      reportsCount: 28,
      riskWeight: 30,
      category: 'fake_refund',
      description: 'Reported mistaken transfer refund scammer',
      reportedAt: DateTime(2026, 7, 15),
    ),
    '0712345678': ThreatIntelligenceRecord(
      identifier: '0712345678',
      type: 'phone',
      reportsCount: 35,
      riskWeight: 30,
      category: 'lottery_scam',
      description: 'Reported fake lottery prize notice caller/sender',
      reportedAt: DateTime(2026, 8, 1),
    ),

    // Known reported deceptive phishing domains
    'telebirr-bonus.xyz': ThreatIntelligenceRecord(
      identifier: 'telebirr-bonus.xyz',
      type: 'domain',
      reportsCount: 89,
      riskWeight: 45,
      category: 'phishing',
      description: 'Deceptive Telebirr clone credential harvest page',
      reportedAt: DateTime(2026, 6, 20),
    ),
    'telebirr-reward.online': ThreatIntelligenceRecord(
      identifier: 'telebirr-reward.online',
      type: 'domain',
      reportsCount: 76,
      riskWeight: 45,
      category: 'phishing',
      description: 'Fake prize redemption portal',
      reportedAt: DateTime(2026, 7, 1),
    ),
    'combanketh-login.top': ThreatIntelligenceRecord(
      identifier: 'combanketh-login.top',
      type: 'domain',
      reportsCount: 64,
      riskWeight: 45,
      category: 'phishing',
      description: 'Cloned CBE mobile login portal',
      reportedAt: DateTime(2026, 7, 22),
    ),
    'ethiopian-lottery.xyz': ThreatIntelligenceRecord(
      identifier: 'ethiopian-lottery.xyz',
      type: 'domain',
      reportsCount: 52,
      riskWeight: 40,
      category: 'fake_lottery',
      description: 'Fake National Lottery prize claim website',
      reportedAt: DateTime(2026, 8, 5),
    ),
  };

  // In-memory fallback maps for web platform runtime
  static final Map<String, String> _memoryFeedback = {};
  static final Map<String, String> _memoryAiCache = {};

  /// Check if a sender or domain has community reputation records on device
  static ThreatIntelligenceRecord? checkReputation(String query) {
    final clean = query.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9\.\-]'), '');
    if (clean.isEmpty) return null;

    if (_communityThreats.containsKey(clean)) {
      return _communityThreats[clean];
    }

    // Check partial domain matches
    for (final entry in _communityThreats.entries) {
      if (entry.value.type == 'domain' && clean.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }

  /// Get user feedback weight impact for a given sender / message hash
  /// Returns negative weight (e.g. -20 for user-marked safe) or positive weight (e.g. +25 for user-reported scam)
  static Future<int> getUserFeedbackWeight(String sender, String message) async {
    final key = _hashKey(sender, message);
    String? feedback;

    if (kIsWeb) {
      feedback = _memoryFeedback[key];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        feedback = prefs.getString('$_userFeedbackPrefix$key') ?? _memoryFeedback[key];
      } catch (_) {
        feedback = _memoryFeedback[key];
      }
    }

    if (feedback == null) return 0;

    switch (feedback) {
      case 'marked_safe':
        return -20; // Weighted trust signal (does not blindly bypass future threats)
      case 'marked_scam':
        return 25; // Weighted risk escalation
      case 'wrong_detection':
        return -15; // Moderate risk mitigation
      default:
        return 0;
    }
  }

  /// Record user feedback ('marked_safe', 'marked_scam', 'wrong_detection')
  static Future<void> saveUserFeedback(String sender, String message, String feedbackType) async {
    final key = _hashKey(sender, message);
    _memoryFeedback[key] = feedbackType;

    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_userFeedbackPrefix$key', feedbackType);
      } catch (_) {}
    }
  }

  /// Retrieve cached Gemini AI result if still valid (under 7-day TTL)
  static Future<CachedAiResult?> getCachedAiResult(String sender, String message) async {
    final key = _hashKey(sender, message);
    String? rawJsonStr;

    if (kIsWeb) {
      rawJsonStr = _memoryAiCache[key];
    } else {
      try {
        final prefs = await SharedPreferences.getInstance();
        rawJsonStr = prefs.getString('$_aiCachePrefix$key') ?? _memoryAiCache[key];
      } catch (_) {
        rawJsonStr = _memoryAiCache[key];
      }
    }

    if (rawJsonStr == null || rawJsonStr.isEmpty) return null;

    try {
      final json = jsonDecode(rawJsonStr) as Map<String, dynamic>;
      final cached = CachedAiResult.fromJson(json);

      if (cached.isExpired) {
        // Expired result, remove from cache
        await _removeAiCache(key);
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  /// Save Gemini AI result into on-device cache
  static Future<void> saveAiResult(String sender, String message, CachedAiResult result) async {
    final key = _hashKey(sender, message);
    final jsonStr = jsonEncode(result.toJson());
    _memoryAiCache[key] = jsonStr;

    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('$_aiCachePrefix$key', jsonStr);
      } catch (_) {}
    }
  }

  static Future<void> _removeAiCache(String key) async {
    _memoryAiCache.remove(key);
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('$_aiCachePrefix$key');
      } catch (_) {}
    }
  }

  static String _hashKey(String sender, String message) {
    final input = '${sender.trim().toLowerCase()}_${message.trim().toLowerCase()}';
    final bytes = utf8.encode(input);
    final encoded = base64Url.encode(bytes).replaceAll('=', '');
    return encoded.length > 24 ? encoded.substring(0, 24) : encoded;
  }
}
