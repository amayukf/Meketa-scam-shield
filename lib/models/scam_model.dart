enum SenderType {
  official,
  personal,
  international,
  unknownShortcode,
  suspiciousName,
}

enum VerdictState {
  safe, // 0 - 19%
  lowRisk, // 20 - 39%
  suspicious, // 40 - 69%
  highRisk, // 70 - 89%
  unknown, // Conflicting signals / Edge case
}

/// Explainable evidence signal contributed by a detection layer
class EvidenceSignal {
  final int layerIndex; // 1 - 10
  final String layerName;
  final int scoreDelta; // e.g. +45 (threat) or -30 (mitigation)
  final String description;
  final bool isMitigation;

  const EvidenceSignal({
    required this.layerIndex,
    required this.layerName,
    required this.scoreDelta,
    required this.description,
    this.isMitigation = false,
  });

  Map<String, dynamic> toMap() => {
        'layerIndex': layerIndex,
        'layerName': layerName,
        'scoreDelta': scoreDelta,
        'description': description,
        'isMitigation': isMitigation,
      };

  factory EvidenceSignal.fromMap(Map<String, dynamic> map) => EvidenceSignal(
        layerIndex: (map['layerIndex'] as num?)?.toInt() ?? 1,
        layerName: map['layerName'] as String? ?? 'Detection Layer',
        scoreDelta: (map['scoreDelta'] as num?)?.toInt() ?? 0,
        description: map['description'] as String? ?? '',
        isMitigation: map['isMitigation'] as bool? ?? false,
      );

  String get formattedImpact => isMitigation ? '-${scoreDelta.abs()}%' : '+${scoreDelta.abs()}%';
}

class ScamModel {
  final int? id;
  final String sender;
  final SenderType senderType;
  final String message;
  final int confidence; // 0-100 Risk Score
  final String classification; // SAFE, LOW_RISK, SUSPICIOUS, HIGH_RISK, UNKNOWN, IMPERSONATION
  final VerdictState verdictState;
  final List<String> flags;
  final List<String> warnings;
  final List<EvidenceSignal> evidence;
  final bool isScam;
  final DateTime timestamp;
  final String? claimedOrganization;
  final String? userFeedback; // 'marked_safe', 'marked_scam', 'wrong_detection', null
  final String? fraudType;
  final String? recommendedAction;
  final bool isAiEnhanced;

  ScamModel({
    this.id,
    required this.sender,
    required this.senderType,
    required this.message,
    required this.confidence,
    required this.classification,
    required this.verdictState,
    required this.flags,
    required this.warnings,
    this.evidence = const [],
    required this.isScam,
    required this.timestamp,
    this.claimedOrganization,
    this.userFeedback,
    this.fraudType,
    this.recommendedAction,
    this.isAiEnhanced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'senderType': senderType.index,
      'message': message,
      'confidence': confidence,
      'classification': classification,
      'flags': flags.join('||'),
      'warnings': warnings.join('||'),
      'isScam': isScam ? 1 : 0,
      'timestamp': timestamp.toIso8601String(),
      'claimedOrganization': claimedOrganization,
      'userFeedback': userFeedback,
      'fraudType': fraudType,
      'recommendedAction': recommendedAction,
    };
  }

  factory ScamModel.fromMap(Map<String, dynamic> map) {
    final senderTypeIdx = map['senderType'] as int? ?? 5;
    final validSenderType =
        senderTypeIdx >= 0 && senderTypeIdx < SenderType.values.length
            ? SenderType.values[senderTypeIdx]
            : SenderType.unknownShortcode;

    final rawFlags = map['flags'] as Object?;
    final flagsList = rawFlags is String && rawFlags.isNotEmpty
        ? rawFlags.split('||')
        : <String>[];

    final rawWarnings = map['warnings'] as Object?;
    final warningsList = rawWarnings is String && rawWarnings.isNotEmpty
        ? rawWarnings.split('||')
        : <String>[];

    final rawConfidence = map['confidence'];
    final confidenceVal = rawConfidence is int
        ? rawConfidence
        : (rawConfidence is num ? rawConfidence.toInt() : 0);

    final rawTimestamp = map['timestamp'] as Object?;
    final timestampVal = rawTimestamp is String
        ? (DateTime.tryParse(rawTimestamp) ?? DateTime.now())
        : DateTime.now();

    final rawIsScam = map['isScam'] as Object?;
    final isScamVal = rawIsScam is int
        ? rawIsScam == 1
        : (rawIsScam is bool ? rawIsScam : false);

    final classificationVal = map['classification'] as String? ??
        (confidenceVal >= 70
            ? 'HIGH_RISK'
            : confidenceVal >= 40
                ? 'SUSPICIOUS'
                : confidenceVal >= 20
                    ? 'LOW_RISK'
                    : 'SAFE');

    final verdictStateVal = _deriveVerdictState(confidenceVal, classificationVal);

    return ScamModel(
      id: map['id'] as int?,
      sender: (map['sender'] as String?) ?? 'Unknown',
      senderType: validSenderType,
      message: (map['message'] as String?) ?? '',
      confidence: confidenceVal.clamp(0, 100),
      classification: classificationVal,
      verdictState: verdictStateVal,
      flags: flagsList,
      warnings: warningsList,
      isScam: isScamVal,
      timestamp: timestampVal,
      claimedOrganization: map['claimedOrganization'] as String?,
      userFeedback: map['userFeedback'] as String?,
      fraudType: map['fraudType'] as String?,
      recommendedAction: map['recommendedAction'] as String?,
    );
  }

  static VerdictState _deriveVerdictState(int confidence, String classification) {
    if (classification == 'UNKNOWN') return VerdictState.unknown;
    if (confidence >= 70) return VerdictState.highRisk;
    if (confidence >= 40) return VerdictState.suspicious;
    if (confidence >= 20) return VerdictState.lowRisk;
    return VerdictState.safe;
  }

  ScamModel copyWith({
    int? id,
    String? sender,
    SenderType? senderType,
    String? message,
    int? confidence,
    String? classification,
    VerdictState? verdictState,
    List<String>? flags,
    List<String>? warnings,
    List<EvidenceSignal>? evidence,
    bool? isScam,
    DateTime? timestamp,
    String? claimedOrganization,
    String? userFeedback,
    String? fraudType,
    String? recommendedAction,
    bool? isAiEnhanced,
  }) {
    return ScamModel(
      id: id ?? this.id,
      sender: sender ?? this.sender,
      senderType: senderType ?? this.senderType,
      message: message ?? this.message,
      confidence: confidence ?? this.confidence,
      classification: classification ?? this.classification,
      verdictState: verdictState ?? this.verdictState,
      flags: flags ?? this.flags,
      warnings: warnings ?? this.warnings,
      evidence: evidence ?? this.evidence,
      isScam: isScam ?? this.isScam,
      timestamp: timestamp ?? this.timestamp,
      claimedOrganization: claimedOrganization ?? this.claimedOrganization,
      userFeedback: userFeedback ?? this.userFeedback,
      fraudType: fraudType ?? this.fraudType,
      recommendedAction: recommendedAction ?? this.recommendedAction,
      isAiEnhanced: isAiEnhanced ?? this.isAiEnhanced,
    );
  }

  String get riskLevel {
    switch (verdictState) {
      case VerdictState.highRisk:
        return 'High Risk';
      case VerdictState.suspicious:
        return 'Suspicious';
      case VerdictState.lowRisk:
        return 'Low Risk';
      case VerdictState.unknown:
        return 'Conflict / Unknown';
      case VerdictState.safe:
        return 'Safe';
    }
  }

  // Decoupled notification policy: only notify on actionable high risk threats
  bool get shouldNotify =>
      confidence >= 70 ||
      (classification == 'IMPERSONATION' && confidence >= 60) ||
      flags.any((f) => f.toLowerCase().contains('otp request') || f.contains('USSD Trap'));
}
