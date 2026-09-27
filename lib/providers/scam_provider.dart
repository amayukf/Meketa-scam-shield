import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scam_model.dart';
import '../services/database_service.dart';
import '../services/scam_detector.dart';
import '../services/gemini_service.dart';
import '../services/threat_intelligence_db.dart';

class ScamProvider extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService.instance;

  List<ScamModel> _alerts = [];
  List<ScamModel> _filteredAlerts = [];
  Map<String, dynamic> _stats = {
    'totalScanned': 0,
    'scamsBlocked': 0,
    'blockRate': 0,
    'familyProtected': 1,
  };
  String _currentFilter = 'all';
  String _currentLanguage = 'English';
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _autoScanEnabled = true;
  bool _allowCloudAiAnalysis = true; // Privacy toggle

  List<ScamModel> get alerts => _alerts;
  List<ScamModel> get filteredAlerts => _filteredAlerts;
  Map<String, dynamic> get stats => _stats;
  String get currentFilter => _currentFilter;
  String get currentLanguage => _currentLanguage;
  bool get isLoading => _isLoading;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get autoScanEnabled => _autoScanEnabled;
  bool get allowCloudAiAnalysis => _allowCloudAiAnalysis;

  int get highRiskCount =>
      _filteredAlerts.where((a) => a.confidence >= 70).length;
  int get mediumRiskCount =>
      _filteredAlerts.where((a) => a.confidence >= 40 && a.confidence < 70).length;
  int get safeCount =>
      _filteredAlerts.where((a) => a.confidence < 40).length;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    await _loadPersistedSettings();
    await loadAlerts();
    await loadStats();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadPersistedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentLanguage = prefs.getString('current_language') ?? 'English';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _autoScanEnabled = prefs.getBool('auto_scan_enabled') ?? true;
      _allowCloudAiAnalysis = prefs.getBool('allow_cloud_ai_analysis') ?? true;
    } catch (e) {
      debugPrint('[ScamProvider] Persisted load error: $e');
    }
  }

  Future<void> setLanguage(String lang) async {
    _currentLanguage = lang;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_language', lang);
    } catch (_) {}
  }

  Future<void> setNotificationsEnabled(bool value) async {
    _notificationsEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
    } catch (_) {}
  }

  Future<void> setAutoScanEnabled(bool value) async {
    _autoScanEnabled = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_scan_enabled', value);
    } catch (_) {}
  }

  Future<void> setAllowCloudAiAnalysis(bool value) async {
    _allowCloudAiAnalysis = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('allow_cloud_ai_analysis', value);
    } catch (_) {}
  }

  Future<void> loadAlerts() async {
    _alerts = await _dbService.getAllAlerts();
    _filteredAlerts = await _dbService.getAlertsByFilter(_currentFilter);
    notifyListeners();
  }

  Future<void> loadStats() async {
    _stats = await _dbService.getStats();
    notifyListeners();
  }

  Future<void> setFilter(String filter) async {
    _currentFilter = filter;
    _filteredAlerts = await _dbService.getAlertsByFilter(filter);
    notifyListeners();
  }

  /// Analyze a message using the 10-Layer Weighted Engine with optional privacy-preserving AI enhancement
  Future<ScamModel> analyzeAndSave(String message, String sender) async {
    // 1. Run the on-device 10-layer detection engine (near-instant offline response)
    final result = await ScamDetector.analyze(message, sender);

    int finalConfidence = result.confidence;
    String finalClassification = result.classification;
    VerdictState finalVerdictState = result.verdictState;
    bool finalIsScam = result.isScam;
    List<String> finalFlags = List.from(result.flags);
    final evidenceList = List<EvidenceSignal>.from(result.evidence);
    String? finalFraudType = result.fraudType;
    String? finalAction = result.recommendedAction;
    bool isAiEnhanced = false;

    // 2. If score is ambiguous (40-69%) AND cloud AI is enabled by user, consult Gemini
    final isAmbiguous = result.confidence >= 40 && result.confidence < 70;
    if (isAmbiguous && _allowCloudAiAnalysis) {
      try {
        final aiResult = await GeminiService.analyzeMessage(
          message,
          sender,
          localFlags: result.flags,
          localConfidence: result.confidence,
          allowCloudAnalysis: _allowCloudAiAnalysis,
        );

        final isRealAIResult = !aiResult.riskFlags.contains(
            'AI analysis unavailable — using offline detection only');

        if (isRealAIResult) {
          isAiEnhanced = true;
          // Merge: weighted blend between local heuristics (60%) and Gemini context (40%)
          final mergedScore = ((result.confidence * 0.6) + (aiResult.confidence * 0.4)).round();
          finalConfidence = mergedScore.clamp(0, 100);

          // Add AI-specific evidence signal
          evidenceList.add(EvidenceSignal(
            layerIndex: 10,
            layerName: 'Layer 10: Gemini 3.5 AI Context Scan',
            scoreDelta: (aiResult.confidence - result.confidence).clamp(-30, 30),
            description: 'AI verified intent: ${aiResult.verdict} (Confidence: ${aiResult.confidence}%)',
            isMitigation: aiResult.verdict == 'SAFE',
          ));

          for (final flag in aiResult.riskFlags) {
            if (!finalFlags.contains(flag)) finalFlags.add(flag);
          }

          if (finalConfidence >= 70) {
            finalVerdictState = VerdictState.highRisk;
            finalClassification = 'HIGH_RISK';
            finalIsScam = true;
          } else if (finalConfidence >= 40) {
            finalVerdictState = VerdictState.suspicious;
            finalClassification = 'SUSPICIOUS';
            finalIsScam = false;
          } else if (finalConfidence >= 20) {
            finalVerdictState = VerdictState.lowRisk;
            finalClassification = 'LOW_RISK';
            finalIsScam = false;
          } else {
            finalVerdictState = VerdictState.safe;
            finalClassification = 'SAFE';
            finalIsScam = false;
          }

          if (aiResult.recommendedAction.isNotEmpty) {
            finalAction = aiResult.recommendedAction;
          }
        }
      } catch (_) {
        // Non-blocking fallback: keep local verdict intact
      }
    }

    final alert = ScamModel(
      sender: sender,
      senderType: result.senderType,
      message: message,
      confidence: finalConfidence,
      classification: finalClassification,
      verdictState: finalVerdictState,
      flags: finalFlags,
      warnings: result.warnings,
      evidence: evidenceList,
      isScam: finalIsScam,
      timestamp: DateTime.now(),
      claimedOrganization: result.claimedOrganization,
      fraudType: finalFraudType,
      recommendedAction: finalAction ?? 'Be cautious with unverified senders.',
      isAiEnhanced: isAiEnhanced,
    );

    final id = await _dbService.insertAlert(alert);
    final savedAlert = alert.copyWith(id: id);

    _alerts.insert(0, savedAlert);
    _applyCurrentFilter();
    _recomputeStatsFromCurrentAlerts();
    notifyListeners();

    return savedAlert;
  }

  void _recomputeStatsFromCurrentAlerts() {
    final totalScanned = _alerts.length;
    final scamsBlocked = _alerts.where((a) => a.isScam).length;
    final blockRate = totalScanned > 0 ? ((scamsBlocked / totalScanned) * 100).round() : 0;
    _stats = {
      'totalScanned': totalScanned,
      'scamsBlocked': scamsBlocked,
      'blockRate': blockRate,
      'familyProtected': 1,
    };
  }

  void _applyCurrentFilter() {
    final now = DateTime.now();
    switch (_currentFilter) {
      case 'today':
        final startOfDay = DateTime(now.year, now.month, now.day);
        _filteredAlerts = _alerts.where((a) => a.timestamp.isAfter(startOfDay)).toList();
        break;
      case 'week':
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        _filteredAlerts = _alerts.where((a) => a.timestamp.isAfter(startOfWeekDay)).toList();
        break;
      case 'month':
        final startOfMonth = DateTime(now.year, now.month, 1);
        _filteredAlerts = _alerts.where((a) => a.timestamp.isAfter(startOfMonth)).toList();
        break;
      case 'all':
      default:
        _filteredAlerts = List.from(_alerts);
        break;
    }
  }

  /// Record user feedback as a weighted reputation signal
  Future<void> recordUserFeedback(int id, String feedbackType) async {
    final alertIndex = _alerts.indexWhere((a) => a.id == id);
    if (alertIndex == -1) return;

    final target = _alerts[alertIndex];
    await ThreatIntelligenceDb.saveUserFeedback(target.sender, target.message, feedbackType);

    int adjustedConfidence = target.confidence;
    VerdictState adjustedVerdict = target.verdictState;
    String adjustedClassification = target.classification;
    bool adjustedIsScam = target.isScam;

    if (feedbackType == 'marked_safe') {
      adjustedConfidence = (adjustedConfidence - 25).clamp(0, 100);
      adjustedIsScam = adjustedConfidence >= 70;
      adjustedVerdict = adjustedConfidence >= 40 ? VerdictState.suspicious : VerdictState.safe;
      adjustedClassification = adjustedConfidence >= 40 ? 'SUSPICIOUS' : 'SAFE';
    } else if (feedbackType == 'marked_scam') {
      adjustedConfidence = (adjustedConfidence + 30).clamp(0, 100);
      adjustedIsScam = true;
      adjustedVerdict = VerdictState.highRisk;
      adjustedClassification = 'HIGH_RISK';
    }

    final updatedAlert = target.copyWith(
      userFeedback: feedbackType,
      confidence: adjustedConfidence,
      verdictState: adjustedVerdict,
      classification: adjustedClassification,
      isScam: adjustedIsScam,
    );

    _alerts[alertIndex] = updatedAlert;
    await _dbService.updateAlert(updatedAlert);

    _applyCurrentFilter();
    _recomputeStatsFromCurrentAlerts();
    notifyListeners();
  }

  Future<void> markAsSafe(int id) async {
    await recordUserFeedback(id, 'marked_safe');
  }

  Future<void> reportAsScam(int id) async {
    await recordUserFeedback(id, 'marked_scam');
  }

  Future<void> deleteAlert(int id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _dbService.deleteAlert(id);
    _applyCurrentFilter();
    _recomputeStatsFromCurrentAlerts();
    notifyListeners();
  }

  int get scamFreePercentage {
    final total = _stats['totalScanned'] as int;
    if (total == 0) return 100;
    final scams = _stats['scamsBlocked'] as int;
    return (((total - scams) / total) * 100).round();
  }
}
