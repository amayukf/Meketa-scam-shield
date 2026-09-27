import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import 'official_registry.dart';
import 'connectivity_service.dart';

class LinkScanResult {
  final String url;
  final bool isMalicious;
  final int maliciousCount;
  final int totalVendors;
  final String verdict;
  final List<String> detectedThreats;
  final String details;

  LinkScanResult({
    required this.url,
    required this.isMalicious,
    required this.maliciousCount,
    required this.totalVendors,
    required this.verdict,
    required this.detectedThreats,
    required this.details,
  });
}

class VirusTotalService {
  static String get _defaultApiKey => AppConfig.virusTotalApiKey;

  static bool get hasValidKey {
    final k = AppConfig.virusTotalApiKey;
    return k.isNotEmpty && !k.startsWith('demo-');
  }

  static Map<String, String> _headers(String apiKey) => {
        'x-apikey': apiKey,
        'Content-Type': 'application/json',
      };

  /// Scan a link using VirusTotal API with local heuristic phishing analysis and privacy guard.
  static Future<LinkScanResult> scanLink(
    String rawUrl, {
    String? apiKey,
    bool allowCloudAnalysis = true,
  }) async {
    String cleanUrl = rawUrl.trim();
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      cleanUrl = 'https://$cleanUrl';
    }

    final heuristicResult = _analyzeHeuristics(cleanUrl);

    // 1. Strict Privacy Enforcement: if cloud analysis is disabled, return local heuristic only
    if (!allowCloudAnalysis) {
      debugPrint('[VirusTotal] Privacy guard: cloud link scan disabled by user.');
      return heuristicResult;
    }

    final keyToUse = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : (hasValidKey ? _defaultApiKey : '');

    if (keyToUse.isEmpty) {
      return heuristicResult;
    }

    if (!(await ConnectivityService.hasInternet)) {
      debugPrint('[VirusTotal] Offline — returning heuristic scan result');
      return heuristicResult;
    }

    try {
      final urlId = base64Url.encode(utf8.encode(cleanUrl)).replaceAll('=', '');
      final response = await http
          .get(
            Uri.parse('https://www.virustotal.com/api/v3/urls/$urlId'),
            headers: _headers(keyToUse),
          )
          .timeout(const Duration(seconds: AppConfig.apiTimeoutSeconds));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['data']['attributes']['last_analysis_stats'] ?? {};
        final malicious = (stats['malicious'] as num?)?.toInt() ?? 0;
        final suspicious = (stats['suspicious'] as num?)?.toInt() ?? 0;
        final harmless = (stats['harmless'] as num?)?.toInt() ?? 0;
        final total = malicious + suspicious + harmless;

        final threats = <String>[];
        if (malicious > 0) {
          threats.add('$malicious security vendors flagged as malicious');
        }
        if (suspicious > 0) {
          threats.add('$suspicious security vendors flagged as suspicious');
        }

        final isDanger = (malicious + suspicious) > 0 || heuristicResult.isMalicious;

        return LinkScanResult(
          url: cleanUrl,
          isMalicious: isDanger,
          maliciousCount: malicious + suspicious,
          totalVendors: total > 0 ? total : 90,
          verdict: isDanger ? 'DANGEROUS / MALICIOUS LINK' : 'SAFE / CLEAN LINK',
          detectedThreats: threats.isNotEmpty ? threats : heuristicResult.detectedThreats,
          details: isDanger
              ? 'VirusTotal API detected potential malware or phishing threats on this domain.'
              : 'VirusTotal API scan confirmed no known malicious indicators for this link.',
        );
      } else if (response.statusCode == 404) {
        return heuristicResult;
      } else {
        debugPrint('[VirusTotal] HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[VirusTotal] Network error: $e');
    }

    return heuristicResult;
  }

  /// Heuristic domain security check for fake bank/telecom phishing links (100% offline)
  static LinkScanResult _analyzeHeuristics(String urlStr) {
    final uri = Uri.tryParse(urlStr);
    final host = uri?.host.toLowerCase() ?? '';
    final threats = <String>[];
    bool isDangerous = false;

    // Check against official Ethiopian domain whitelist
    final isOfficial = OfficialRegistry.isOfficialDomain(host);

    if (isOfficial) {
      return LinkScanResult(
        url: urlStr,
        isMalicious: false,
        maliciousCount: 0,
        totalVendors: 90,
        verdict: 'OFFICIAL & VERIFIED DOMAIN',
        detectedThreats: [],
        details: 'This link belongs to a verified official Ethiopian bank or telecom domain.',
      );
    }

    // Phishing keyword checks on unofficial domain
    final lowerUrl = urlStr.toLowerCase();
    if (RegExp(r'(telebirr|ethiotelecom|cbe|cbebirr|abyssinia|awash|dashen)').hasMatch(host)) {
      isDangerous = true;
      threats.add('Phishing / Typosquatting domain impersonating official bank name');
    }

    if (RegExp(r'(login|verify|update|claim|bonus|free|account|winner|award|gift|telegram)').hasMatch(lowerUrl) &&
        !isOfficial) {
      threats.add('Suspicious account verification or reward claim path on unverified domain');
    }

    // High risk TLDs
    if (RegExp(r'\.(tk|ml|ga|cf|gq|xyz|top|work|buzz|club|online|site|app|cc)$').hasMatch(host)) {
      threats.add('Domain uses high-risk top-level domain frequently associated with scams');
    }

    if (threats.isNotEmpty) isDangerous = true;

    return LinkScanResult(
      url: urlStr,
      isMalicious: isDangerous,
      maliciousCount: isDangerous ? 1 : 0,
      totalVendors: 90,
      verdict: isDangerous ? 'SUSPICIOUS / PHISHING LINK' : 'CLEAN / UNKNOWN LINK',
      detectedThreats: threats,
      details: isDangerous
          ? 'Security analysis flagged suspicious patterns or impersonation indicators on this URL.'
          : 'No immediate phishing or typosquatting indicators found on this link structure.',
    );
  }
}
