import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Structured result representing the exact Odit Verify (v.odit.et) API response
class OditVerifyResult {
  final bool ok;
  final String providerKey;
  final String resolvedUrl;
  final int? httpStatus;
  final String? fetchedAt;
  final bool cached;
  final int? rawHtmlLength;
  final String? egressSource;
  final String? error;
  final Map<String, dynamic>? receipt;
  final Map<String, dynamic> rawJson;
  final bool isDuplicate;
  final String? lastVerifiedAt;
  final int timesChecked;

  OditVerifyResult({
    required this.ok,
    required this.providerKey,
    required this.resolvedUrl,
    this.httpStatus,
    this.fetchedAt,
    this.cached = false,
    this.rawHtmlLength,
    this.egressSource,
    this.error,
    this.receipt,
    Map<String, dynamic>? rawJson,
    this.isDuplicate = false,
    this.lastVerifiedAt,
    this.timesChecked = 1,
  }) : rawJson = rawJson ?? (receipt != null ? {'ok': ok, 'providerKey': providerKey, 'resolvedUrl': resolvedUrl, 'receipt': receipt} : {'ok': ok, 'error': error});

  factory OditVerifyResult.fromJson(
    Map<String, dynamic> json, {
    bool isDuplicate = false,
    String? lastVerifiedAt,
    int timesChecked = 1,
  }) {
    final receiptData = json['receipt'] as Map<String, dynamic>?;
    
    // Handle error field which can be a string or an object { code: ..., message: ... }
    String? parsedError;
    if (json['error'] != null) {
      if (json['error'] is Map) {
        parsedError = (json['error'] as Map)['message']?.toString() ?? json['error'].toString();
      } else {
        parsedError = json['error'].toString();
      }
    }

    return OditVerifyResult(
      ok: json['ok'] == true,
      providerKey: (json['providerKey'] ?? '').toString(),
      resolvedUrl: (json['resolvedUrl'] ?? '').toString(),
      httpStatus: json['httpStatus'] is int ? json['httpStatus'] as int : null,
      fetchedAt: json['fetchedAt']?.toString(),
      cached: json['cached'] == true,
      rawHtmlLength: json['rawHtmlLength'] is int ? json['rawHtmlLength'] as int : null,
      egressSource: json['egressSource']?.toString(),
      error: parsedError,
      receipt: receiptData,
      rawJson: json,
      isDuplicate: isDuplicate,
      lastVerifiedAt: lastVerifiedAt,
      timesChecked: timesChecked,
    );
  }

  // --- Normalized getters for unified UI presentation ---

  String get providerDisplayName {
    final key = providerKey.toLowerCase();
    if (key.contains('telebirr')) return 'Telebirr (Ethio Telecom)';
    if (key.contains('cbe')) return 'Commercial Bank of Ethiopia (CBE)';
    if (key.contains('boa') || key.contains('abyssinia')) return 'Bank of Abyssinia (BoA)';
    if (key.contains('awash')) return 'Awash Bank (AwashPay)';
    if (key.contains('zemen')) return 'Zemen Bank';
    return providerKey.isNotEmpty ? providerKey.toUpperCase() : 'Ethiopian Banking Network';
  }

  String get totalAmountFormatted {
    if (receipt == null) return '0.00 ETB';
    final r = receipt!;

    if (r['totalPaidAmount'] != null) {
      final val = r['totalPaidAmount'].toString();
      return val.endsWith('Birr') || val.endsWith('ETB') ? val : '$val ETB';
    }

    if (r['totalAmount'] != null) {
      final amt = r['totalAmount'];
      final curr = (r['currency'] ?? 'ETB').toString();
      if (amt is num) {
        return '${_formatNumber(amt.toDouble())} $curr';
      }
      return '$amt $curr';
    }

    if (r['transferredAmount'] != null) {
      final amt = r['transferredAmount'];
      final curr = (r['currency'] ?? 'ETB').toString();
      if (amt is num) {
        return '${_formatNumber(amt.toDouble())} $curr';
      }
      return '$amt $curr';
    }

    if (r['settledAmount'] != null) {
      final val = r['settledAmount'].toString();
      return val.endsWith('Birr') || val.endsWith('ETB') ? val : '$val ETB';
    }

    return 'Verified Receipt';
  }

  String get settledAmountFormatted {
    if (receipt == null) return '';
    final r = receipt!;
    if (r['settledAmount'] != null) return r['settledAmount'].toString();
    if (r['transferredAmount'] != null) {
      final amt = r['transferredAmount'];
      return amt is num ? '${_formatNumber(amt.toDouble())} ETB' : '$amt ETB';
    }
    return totalAmountFormatted;
  }

  String get feeFormatted {
    if (receipt == null) return '';
    final r = receipt!;
    final fee = r['serviceFee'] ?? r['serviceCharge'];
    final vat = r['serviceFeeVAT'] ?? r['vat'];

    if (fee != null && vat != null) {
      return '$fee + VAT $vat';
    } else if (fee != null) {
      return fee is num ? '${_formatNumber(fee.toDouble())} ETB' : fee.toString();
    }
    return '';
  }

  String get payerName {
    if (receipt == null) return 'Customer';
    final r = receipt!;
    return (r['payerName'] ?? r['customerName'] ?? 'Verified Customer').toString();
  }

  String get payerAccount {
    if (receipt == null) return '';
    final r = receipt!;
    return (r['payerTelebirrNo'] ?? r['payerAccount'] ?? r['payerPhone'] ?? '').toString();
  }

  String get payerAccountType {
    if (receipt == null) return '';
    return (receipt!['payerAccountType'] ?? '').toString();
  }

  String get receiverName {
    if (receipt == null) return 'Merchant / Recipient';
    final r = receipt!;
    return (r['creditedPartyName'] ?? r['receiverName'] ?? r['receiver'] ?? 'Verified Recipient').toString();
  }

  String get receiverAccount {
    if (receipt == null) return '';
    final r = receipt!;
    return (r['creditedPartyAccountNo'] ?? r['receiverAccount'] ?? '').toString();
  }

  String get referenceNumber {
    if (receipt == null) return '';
    final r = receipt!;
    return (r['receiptNo'] ?? r['reference'] ?? r['transactionNo'] ?? '').toString();
  }

  String get paymentDateFormatted {
    if (receipt == null) return fetchedAt ?? '';
    final r = receipt!;
    return (r['paymentDate'] ?? r['timestamp'] ?? fetchedAt ?? '').toString();
  }

  String get transactionStatus {
    if (receipt == null) return ok ? 'Completed' : 'Failed';
    final r = receipt!;
    return (r['transactionStatus'] ?? r['status'] ?? (ok ? 'Completed' : 'Failed')).toString();
  }

  String get paymentReason {
    if (receipt == null) return '';
    final r = receipt!;
    return (r['paymentReason'] ?? r['reason'] ?? r['narrative'] ?? '').toString();
  }

  String get paymentChannel {
    if (receipt == null) return 'Official Gateway';
    final r = receipt!;
    return (r['paymentChannel'] ?? r['paymentMode'] ?? r['channel'] ?? 'API/App').toString();
  }

  String get sourceBadge {
    if (receipt == null) return egressSource ?? 'Odit Direct Egress';
    final src = receipt!['source']?.toString();
    if (src == 'telebirr-html') return 'Ethio Telecom Gateway';
    if (src == 'cbe-pdf') return 'CBE PDF Parser';
    if (src == 'boa-json') return 'Bank of Abyssinia API';
    if (src == 'awash-html') return 'AwashPay Gateway';
    if (src == 'zemen-pdf') return 'Zemen Bank Core';
    return egressSource ?? 'Upstream Egress';
  }

  String get branch {
    if (receipt == null) return '';
    return (receipt!['branch'] ?? '').toString();
  }

  String get vatReceiptNo {
    if (receipt == null) return '';
    return (receipt!['vatReceiptNo'] ?? '').toString();
  }

  static String _formatNumber(double val) {
    final parts = val.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
    return '$intPart.${parts[1]}';
  }
}

class OditVerifyService {
  static String get _apiKey => AppConfig.oditVerifyApiKey;
  
  static String get _verifyEndpoint {
    if (kIsWeb) {
      // In web browser, proxy through local server endpoint to avoid browser CORS preflight blocking
      final origin = Uri.base.origin;
      return '$origin/api/verify';
    }
    return 'https://v.odit.et/api/verify';
  }

  static bool get hasValidKey => _apiKey.isNotEmpty && _apiKey.startsWith('vk_');

  static Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'content-type': 'application/json',
      };

  // Web-safe in-memory cache for duplicate tracking
  static final Map<String, String> _memoryStringPrefs = {};
  static final Map<String, int> _memoryIntPrefs = {};

  static Future<String?> _getPrefString(String key) async {
    if (kIsWeb) return _memoryStringPrefs[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return _memoryStringPrefs[key];
    }
  }

  static Future<void> _setPrefString(String key, String value) async {
    _memoryStringPrefs[key] = value;
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(key, value);
      } catch (_) {}
    }
  }

  static Future<int?> _getPrefInt(String key) async {
    if (kIsWeb) return _memoryIntPrefs[key];
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key);
    } catch (_) {
      return _memoryIntPrefs[key];
    }
  }

  static Future<void> _setPrefInt(String key, int value) async {
    _memoryIntPrefs[key] = value;
    if (!kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(key, value);
      } catch (_) {}
    }
  }

  /// Verify a receipt reference or URL directly at the source via live Odit Verify API
  static Future<OditVerifyResult> verify(
    String receiptUrlOrRef, {
    String selectedProvider = 'Telebirr',
    String? accountSuffix,
  }) async {
    final cleanInput = receiptUrlOrRef.trim();
    if (cleanInput.isEmpty) {
      return OditVerifyResult(
        ok: false,
        providerKey: selectedProvider,
        resolvedUrl: '',
        error: 'Please enter a transaction reference or receipt URL.',
        rawJson: {'ok': false, 'error': 'Empty input'},
      );
    }

    final cleanRefUpper = _extractReference(cleanInput).toUpperCase();
    final historyKey = 'verified_ref_$cleanRefUpper';
    final previousScanTime = await _getPrefString(historyKey);
    final timesKey = 'verified_count_$cleanRefUpper';
    final timesChecked = ((await _getPrefInt(timesKey)) ?? 0) + 1;
    final nowStr = _formatTimestamp(DateTime.now());

    final isFullUrl = cleanInput.startsWith('http://') || cleanInput.startsWith('https://');

    Map<String, dynamic> requestPayload;
    if (isFullUrl) {
      requestPayload = {'url': cleanInput};
    } else if (selectedProvider.toLowerCase() == 'telebirr' && cleanInput.length <= 16 && !cleanInput.contains('/')) {
      // Telebirr supports direct shorthand reference payload
      requestPayload = {'reference': cleanInput};
    } else {
      final targetUrl = _buildTargetUrl(cleanInput, selectedProvider);
      requestPayload = {'url': targetUrl};
    }

    debugPrint('[OditVerify] Sending to $_verifyEndpoint with payload: ${jsonEncode(requestPayload)}');

    try {
      final response = await http
          .post(
            Uri.parse(_verifyEndpoint),
            headers: _headers,
            body: jsonEncode(requestPayload),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[OditVerify] Live API Response HTTP ${response.statusCode}: ${response.body}');

      Map<String, dynamic> data;
      try {
        data = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (jsonErr) {
        data = {
          'ok': false,
          'httpStatus': response.statusCode,
          'error': 'Non-JSON response from upstream: ${response.body}',
          'rawBody': response.body,
        };
      }

      final result = OditVerifyResult.fromJson(
        data,
        isDuplicate: previousScanTime != null,
        lastVerifiedAt: previousScanTime,
        timesChecked: timesChecked,
      );

      if (result.ok) {
        await _setPrefString(historyKey, nowStr);
        await _setPrefInt(timesKey, timesChecked);
      }

      return result;
    } catch (e) {
      debugPrint('[OditVerify] Network error calling live API: $e');
      return OditVerifyResult(
        ok: false,
        providerKey: selectedProvider,
        resolvedUrl: _buildTargetUrl(cleanInput, selectedProvider),
        error: 'Failed to connect to Odit Verify API: $e',
        rawJson: {'ok': false, 'error': e.toString()},
      );
    }
  }

  static String _extractReference(String input) {
    if (!input.startsWith('http')) return input;
    final uri = Uri.tryParse(input);
    if (uri == null) return input;
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return uri.queryParameters['id'] ?? uri.queryParameters['trx'] ?? input;
  }

  static String _buildTargetUrl(String ref, String provider) {
    final p = provider.toLowerCase();
    if (p.contains('telebirr')) {
      return 'https://transactioninfo.ethiotelecom.et/receipt/$ref';
    } else if (p.contains('cbe')) {
      if (ref.startsWith('FT') || ref.startsWith('ft')) {
        return 'https://apps.cbe.com.et:100/?id=$ref';
      }
      return 'https://mbreciept.cbe.com.et/$ref';
    } else if (p.contains('awash')) {
      return 'https://awashpay.awashbank.com:8225/-$ref';
    } else if (p.contains('boa') || p.contains('abyssinia')) {
      return 'https://cs.bankofabyssinia.com/slip/?trx=$ref';
    } else if (p.contains('zemen')) {
      return 'https://share.zemenbank.com/ft/$ref/pdf';
    }
    return 'https://transactioninfo.ethiotelecom.et/receipt/$ref';
  }

  static String _formatTimestamp(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
