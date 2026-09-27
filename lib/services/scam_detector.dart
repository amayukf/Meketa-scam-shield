import '../models/scam_model.dart';
import 'official_registry.dart';
import 'threat_intelligence_db.dart';

class DetectionResult {
  final int confidence; // 0-100 Risk Score
  final String classification;
  final VerdictState verdictState;
  final List<String> flags;
  final List<String> warnings;
  final List<EvidenceSignal> evidence;
  final bool isScam;
  final bool shouldNotify;
  final SenderType senderType;
  final String? claimedOrganization;
  final String? fraudType;
  final String? recommendedAction;
  final bool hasSignalConflict;

  DetectionResult({
    required this.confidence,
    required this.classification,
    required this.verdictState,
    required this.flags,
    required this.warnings,
    required this.evidence,
    required this.isScam,
    required this.shouldNotify,
    required this.senderType,
    this.claimedOrganization,
    this.fraudType,
    this.recommendedAction,
    this.hasSignalConflict = false,
  });
}

class ScamDetector {
  // Regex patterns across English, Amharic (አማርኛ), and Afaan Oromoo

  // Layer 4: Credential & OTP Theft Detector with Disclaimer Protection
  static bool _isOtpTheftDemand(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('never share') ||
        lower.contains('do not share') ||
        lower.contains("don't share") ||
        lower.contains('ለማንም') ||
        lower.contains('እንዳያካፍሉ')) {
      return false;
    }

    return RegExp(
      r'(send|share|reply|provide|give|forward|enter|tell|ላክ|ላኩ|ስጥ|ስጡ|አስገባ|ይላኩ|ergi|kenn)\s+.*(otp|pin\b|password|code|verification|ኮድ|የይለፍ\s*ቃል|ኦቲፒ|koodii|passwordii)',
      caseSensitive: false,
    ).hasMatch(message);
  }

  static final RegExp _otpDeliveryPattern = RegExp(
    r'(your\s+(otp|code|verification\s+code)\s+is|is\s+your\s+(otp|verification\s+code)|የማረጋገጫ\s+ኮድዎ|koodiin\s+keessan|do\s+not\s+share|never\s+share|ለማንም\s+እንዳያካፍሉ)',
    caseSensitive: false,
  );

  // Layer 5: Social Engineering Patterns
  static final RegExp _fakeRefundPattern = RegExp(
    r'(by\s+mistake|accidentally|wrong\s+transfer|በስህተት|ተሳስቼ|dogoggoraan)',
    caseSensitive: false,
  );

  static final RegExp _fakePrizePattern = RegExp(
    r'(won|winner|reward|congratulations|congrats|ተሸልሟል|እድለኛ|ተመርጠዋል|badhaasa|badhaafamte)',
    caseSensitive: false,
  );

  static final RegExp _feeDemandPattern = RegExp(
    r'(pay|fee|registration\s+fee|processing\s+fee|charge|ክፈል|ክፈሉ|ክፍያ|kaffali|kaffaltii)',
    caseSensitive: false,
  );

  static final RegExp _urgencyThreatPattern = RegExp(
    r'(urgent|immediately|act\s+now|blocked|closed|suspended|restricted|አስቸኳይ|ታግደዋል|ይዘጋል|ይቋረጣል|ariifachiisaa)',
    caseSensitive: false,
  );

  // Layer 6: Malicious USSD Dial Strings (*806*..., *127*..., *889*..., *21*...)
  static final RegExp _ussdPattern = RegExp(
    r'(\*806\*\d+\*\d+#|\*127\*\d+\*\d+#|\*889\*\d+\*\d+#|\*21\*\d+#|\*62\*\d+#|\*67\*\d+#|\*\d{3}\*[\d\*]+#)',
    caseSensitive: false,
  );

  // Layer 7: Deceptive URL & Domain Patterns
  static final RegExp _urlPattern = RegExp(
    r'(https?://[^\s]+|[a-zA-Z0-9\-]+\.(xyz|top|online|site|club|work|buzz|info|cc|tk|ml|ga|gq)/[^\s]*)',
    caseSensitive: false,
  );

  static final RegExp _phishingCloneDomainPattern = RegExp(
    r'(telebirr|cbe|combank|ethiotelecom|ethio-telecom|bankofabyssinia|dashen|awash)[a-zA-Z0-9\-]*\.(xyz|top|online|site|club|work|biz|info|cc)',
    caseSensitive: false,
  );

  // Layer 3: Legitimate Context & Conversational Patterns (False-Positive Shield)
  static final RegExp _conversationalGreetings = RegExp(
    r'^(selam|salam|hi|hello|hey|dehna\s+neh|dehna\s+nesh|endet\s+neh|nagaa|akkam|እንደምን\s+አለህ|ሰላም|ደህና\s+ነህ|ሰላም\s+ነው)\b',
    caseSensitive: false,
  );

  static final RegExp _cleanPersonalTransferPattern = RegExp(
    r'^(acc(ount)?\s*(no|number|num)?\s*:?\s*\d{8,16}|አካውንት\s*:?\s*\d{8,16}|herrega\s*:?\s*\d{8,16})',
    caseSensitive: false,
  );

  static final RegExp _legitimateBankNoticeSyntax = RegExp(
    r'(dear\s+customer|account\s+\w+\s+has\s+been|debited\s+by|credited\s+by|txn\s+id|balance\s+is|ref\s*no|a/c\b|ሒሳብዎ\s+በ|ብር\s+ገቢ|ብር\s+ወጪ|ቀሪ\s+ሒሳብ)',
    caseSensitive: false,
  );

  /// Analyze a message using the 10-Layer Weighted Evidence Engine (Near-instant offline response)
  static Future<DetectionResult> analyze(String message, String sender) async {
    int totalScore = 0;
    final flags = <String>[];
    final warnings = <String>[];
    final evidence = <EvidenceSignal>[];
    String? claimedOrg;
    String? fraudType;
    String? recommendedAction;
    bool hasSignalConflict = false;

    // --- SENDER CLASSIFICATION ---
    final verifiedOrg = OfficialRegistry.getVerifiedOrganization(sender);
    final impersonation = OfficialRegistry.detectImpersonation(sender, message);
    final isPersonal = OfficialRegistry.isPersonalNumber(sender);

    SenderType senderType;
    if (verifiedOrg != null) {
      senderType = SenderType.official;
    } else if (isPersonal) {
      senderType = SenderType.personal;
    } else if (RegExp(r'^\+?(?!251)\d{6,}$').hasMatch(sender)) {
      senderType = SenderType.international;
    } else if (RegExp(r'^\d{3,5}$').hasMatch(sender)) {
      senderType = SenderType.unknownShortcode;
    } else {
      senderType = SenderType.suspiciousName;
    }

    // --- PAYLOAD SIGNAL EXTRACTIONS ---
    final hasUssd = _ussdPattern.hasMatch(message);
    final hasOtpDemand = _isOtpTheftDemand(message);
    final hasOtpDelivery = _otpDeliveryPattern.hasMatch(message);
    final hasPhishingCloneDomain = _phishingCloneDomainPattern.hasMatch(message);
    final hasUrl = _urlPattern.hasMatch(message);
    final hasFakeRefund = _fakeRefundPattern.hasMatch(message);
    final hasFakePrize = _fakePrizePattern.hasMatch(message);
    final hasUrgency = _urgencyThreatPattern.hasMatch(message);
    final hasConversationalContext = _conversationalGreetings.hasMatch(message.trim());
    final hasCleanPersonalTransfer = _cleanPersonalTransferPattern.hasMatch(message.trim());
    final hasLegitimateBankSyntax = _legitimateBankNoticeSyntax.hasMatch(message);

    // =========================================================================
    // LAYER 1: SENDER AUTHORITY & SHORTCODE TRUST (On-Device)
    // =========================================================================
    if (verifiedOrg != null) {
      claimedOrg = verifiedOrg.name;
      // Mitigate risk strongly, but never guarantee safety if hostile payload exists
      const trustWeight = -40;
      totalScore += trustWeight;
      evidence.add(EvidenceSignal(
        layerIndex: 1,
        layerName: 'Layer 1: Sender Authority',
        scoreDelta: trustWeight,
        description: 'Verified official shortcode (${verifiedOrg.name})',
        isMitigation: true,
      ));
      warnings.add('Verified official sender (${verifiedOrg.name})');
    }

    // =========================================================================
    // LAYER 2: PERSONAL-TO-OFFICIAL IMPERSONATION DETECTOR (On-Device)
    // =========================================================================
    if (impersonation.isImpersonation) {
      final impWeight = impersonation.riskWeight > 0 ? impersonation.riskWeight : 55;
      totalScore += impWeight;
      claimedOrg = impersonation.claimedOrgName ?? 'Official Service';
      fraudType = 'Official Identity Impersonation';
      flags.add(impersonation.reason ?? 'Personal number claims official authority');
      evidence.add(EvidenceSignal(
        layerIndex: 2,
        layerName: 'Layer 2: Impersonation Interceptor',
        scoreDelta: impWeight,
        description: impersonation.reason ?? 'Personal sender claims official service',
      ));

      // If personal number also fakes debit/credit bank syntax
      if (hasLegitimateBankSyntax || message.toLowerCase().contains('credited') || message.toLowerCase().contains('received')) {
        const fakeBankNoticeRisk = 25;
        totalScore += fakeBankNoticeRisk;
        flags.add('Personal sender fakes bank credit / transaction notification');
        evidence.add(const EvidenceSignal(
          layerIndex: 2,
          layerName: 'Layer 2: Fake Bank Notification Body',
          scoreDelta: fakeBankNoticeRisk,
          description: 'Personal mobile number transmitting fraudulent bank credit alert',
        ));
      }
    }

    // =========================================================================
    // LAYER 3: CONTEXTUAL INTENT & FALSE-POSITIVE SHIELD (On-Device)
    // =========================================================================
    if (isPersonal && !impersonation.isImpersonation && !hasOtpDemand && !hasUssd && !hasPhishingCloneDomain && !hasFakeRefund && !hasFakePrize) {
      if (hasConversationalContext) {
        // Natural conversational greeting between personal contacts
        const convMitigation = -30;
        totalScore += convMitigation;
        evidence.add(const EvidenceSignal(
          layerIndex: 3,
          layerName: 'Layer 3: Conversational Context',
          scoreDelta: convMitigation,
          description: 'Recognized standard conversational greeting and friendly context',
          isMitigation: true,
        ));
      }

      if (hasCleanPersonalTransfer && !hasUrgency) {
        // Clean peer-to-peer account number sharing without refund pressure
        const cleanAccMitigation = -25;
        totalScore += cleanAccMitigation;
        evidence.add(const EvidenceSignal(
          layerIndex: 3,
          layerName: 'Layer 3: Clean Account Sharing',
          scoreDelta: cleanAccMitigation,
          description: 'Benign personal account number sharing without coercive intent',
          isMitigation: true,
        ));
      }
    }

    if (hasLegitimateBankSyntax && verifiedOrg != null && !hasOtpDemand && !hasPhishingCloneDomain && !hasUssd) {
      const bankNoticeMitigation = -20;
      totalScore += bankNoticeMitigation;
      evidence.add(const EvidenceSignal(
        layerIndex: 3,
        layerName: 'Layer 3: Legitimate Bank Syntax',
        scoreDelta: bankNoticeMitigation,
        description: 'Matches standard verified banking debit/credit notification syntax',
        isMitigation: true,
      ));
    }

    // =========================================================================
    // LAYER 4: MULTILINGUAL CREDENTIAL & OTP THEFT DEFENSE (On-Device)
    // =========================================================================
    if (hasOtpDemand) {
      // Coercive demand to forward or share an OTP
      const otpRisk = 75;
      totalScore += otpRisk;
      fraudType = fraudType ?? 'Credential & Account Theft';
      flags.add('Demands sensitive OTP, PIN, or verification password');
      evidence.add(const EvidenceSignal(
        layerIndex: 4,
        layerName: 'Layer 4: Credential Theft Defense',
        scoreDelta: otpRisk,
        description: 'Explicit attempt to steal OTP/PIN or account verification codes',
      ));
      recommendedAction = 'NEVER share your OTP or PIN with anyone, even if they claim to be a bank agent.';
    } else if (hasOtpDelivery && verifiedOrg != null) {
      // Legitimate OTP delivery notification with disclaimer
      const otpDeliveryMitigation = -20;
      totalScore += otpDeliveryMitigation;
      evidence.add(const EvidenceSignal(
        layerIndex: 4,
        layerName: 'Layer 4: Legitimate OTP Delivery',
        scoreDelta: otpDeliveryMitigation,
        description: 'Standard security OTP delivery notice with security warning',
        isMitigation: true,
      ));
    }

    // =========================================================================
    // LAYER 5: SOCIAL ENGINEERING & BEHAVIORAL PRESSURE (On-Device)
    // =========================================================================
    if (hasFakeRefund) {
      const refundRisk = 45;
      totalScore += refundRisk;
      fraudType = fraudType ?? 'Fake Mistaken Transfer Scam';
      flags.add('Claims accidental transfer / mistaken refund request');
      evidence.add(const EvidenceSignal(
        layerIndex: 5,
        layerName: 'Layer 5: Social Engineering Heuristic',
        scoreDelta: refundRisk,
        description: 'Claims money was sent by mistake to induce unverified refund',
      ));
      recommendedAction = 'Check your actual bank balance directly (*889# or *127#) before sending any money.';
    }

    if (hasFakePrize) {
      const prizeRisk = 40;
      totalScore += prizeRisk;
      fraudType = fraudType ?? 'Fake Lottery & Prize Scam';
      flags.add('Claims lottery / prize reward to lure recipient');
      evidence.add(const EvidenceSignal(
        layerIndex: 5,
        layerName: 'Layer 5: Lottery Lure Heuristic',
        scoreDelta: prizeRisk,
        description: 'Promises unverified prize money or lottery reward',
      ));
      recommendedAction = 'Do not pay any processing fee or share personal details to claim unexpected prizes.';
    }

    final hasFeeDemand = _feeDemandPattern.hasMatch(message);
    if (hasFeeDemand && (hasFakePrize || hasFakeRefund || impersonation.isImpersonation || isPersonal)) {
      const feeRisk = 35;
      totalScore += feeRisk;
      flags.add('Requests advance payment or processing fee');
      evidence.add(const EvidenceSignal(
        layerIndex: 5,
        layerName: 'Layer 5: Advance Fee Demand',
        scoreDelta: feeRisk,
        description: 'Demands upfront payment or registration fee under false pretenses',
      ));
    }

    if (hasUrgency && (impersonation.isImpersonation || hasFakeRefund || hasFakePrize || hasOtpDemand || hasUrl)) {
      const urgencyRisk = 20;
      totalScore += urgencyRisk;
      flags.add('Uses psychological urgency or threat of account suspension');
      evidence.add(const EvidenceSignal(
        layerIndex: 5,
        layerName: 'Layer 5: Urgency Pressure Cues',
        scoreDelta: urgencyRisk,
        description: 'Employs artificial time pressure or threat of account restrictions',
      ));
    }

    // =========================================================================
    // LAYER 6: USSD TRAP & MALICIOUS DIAL-CODE INTERCEPTOR (On-Device)
    // =========================================================================
    if (hasUssd) {
      // Confirmed dangerous USSD pattern (e.g. transfer airtime or forward calls)
      const ussdRisk = 75;
      totalScore += ussdRisk;
      fraudType = 'Malicious USSD Money / Airtime Trap';
      flags.add('Contains stealth USSD dial code designed to transfer airtime or forward SIM calls');
      evidence.add(const EvidenceSignal(
        layerIndex: 6,
        layerName: 'Layer 6: USSD Trap Interceptor',
        scoreDelta: ussdRisk,
        description: 'Malicious USSD string (*806*...# or call-forwarding *21*...) detected',
      ));
      recommendedAction = 'DO NOT dial the code in this message. It will execute an unauthorized transfer.';
    }

    // =========================================================================
    // LAYER 7: TYPO-SQUATTING & DECEPTIVE PHISHING DOMAINS (On-Device)
    // =========================================================================
    if (hasPhishingCloneDomain) {
      const typoRisk = 70;
      totalScore += typoRisk;
      fraudType = fraudType ?? 'Deceptive Phishing Link';
      flags.add('Contains lookalike phishing clone domain targeting Ethiopian institutions');
      flags.add('Contains suspicious external web link');
      evidence.add(const EvidenceSignal(
        layerIndex: 7,
        layerName: 'Layer 7: Typo-Squatting Analyzer',
        scoreDelta: typoRisk,
        description: 'Deceptive clone domain mimicking Ethiopian bank/telecom portal',
      ));
      recommendedAction = 'Do not open this link or enter your credentials on this page.';
    } else if (hasUrl && !impersonation.isImpersonation && verifiedOrg == null) {
      // General external link from unverified sender
      const genericUrlRisk = 25;
      totalScore += genericUrlRisk;
      flags.add('Contains external unverified web link');
      flags.add('Contains suspicious external web link');
      evidence.add(const EvidenceSignal(
        layerIndex: 7,
        layerName: 'Layer 7: External URL Signal',
        scoreDelta: genericUrlRisk,
        description: 'Unverified external web link from personal or non-standard sender',
      ));
    }

    // =========================================================================
    // LAYER 8: LOCAL COMMUNITY THREAT INTELLIGENCE & REPUTATION DB (On-Device)
    // =========================================================================
    final reputationSender = ThreatIntelligenceDb.checkReputation(sender);
    if (reputationSender != null) {
      final repWeight = reputationSender.riskWeight;
      totalScore += repWeight;
      flags.add('Sender matches community threat intelligence (${reputationSender.description})');
      evidence.add(EvidenceSignal(
        layerIndex: 8,
        layerName: 'Layer 8: Community Reputation DB',
        scoreDelta: repWeight,
        description: '${reputationSender.reportsCount} community reports for ${reputationSender.category}',
      ));
    }

    // Check user feedback weighted signal
    final feedbackWeight = await ThreatIntelligenceDb.getUserFeedbackWeight(sender, message);
    if (feedbackWeight != 0) {
      totalScore += feedbackWeight;
      evidence.add(EvidenceSignal(
        layerIndex: 8,
        layerName: 'Layer 8: User Feedback Memory',
        scoreDelta: feedbackWeight,
        description: feedbackWeight < 0 ? 'User previously marked as safe' : 'User previously reported as scam',
        isMitigation: feedbackWeight < 0,
      ));
    }

    // =========================================================================
    // CONFLICT RESOLUTION MATRIX
    // =========================================================================
    // If official sender header contains high-risk malicious payload (OTP theft, USSD trap, Phishing domain)
    if (verifiedOrg != null && (hasOtpDemand || hasUssd || hasPhishingCloneDomain)) {
      hasSignalConflict = true;
      // Neutralize trust mitigation because header may be spoofed or compromised
      totalScore += 50;
      flags.add('Signal Conflict: Official Sender ID with Malicious Payload (Potential Header Spoofing)');
      evidence.add(const EvidenceSignal(
        layerIndex: 1,
        layerName: 'Conflict Matrix: Header Spoofing Warning',
        scoreDelta: 50,
        description: 'Verified sender ID contains high-risk threat payload; trust discount neutralized',
      ));
    }

    // Calibrate confidence score between 0 and 100
    final confidence = totalScore.clamp(0, 100);

    // Discrete 5-State Verdict Mapping
    VerdictState verdictState;
    String classification;

    if (hasSignalConflict && confidence >= 60) {
      verdictState = VerdictState.unknown;
      classification = 'UNKNOWN';
    } else if (confidence >= 70) {
      verdictState = VerdictState.highRisk;
      classification = impersonation.isImpersonation ? 'IMPERSONATION' : 'HIGH_RISK';
    } else if (confidence >= 40) {
      verdictState = VerdictState.suspicious;
      classification = 'SUSPICIOUS';
    } else if (confidence >= 20) {
      verdictState = VerdictState.lowRisk;
      classification = 'LOW_RISK';
    } else {
      verdictState = VerdictState.safe;
      classification = verifiedOrg != null ? 'LIKELY_OFFICIAL' : 'SAFE';
    }

    final isScam = confidence >= 70;
    // Decoupled notification dispatch: only alert when confidence is high or critical
    final shouldNotify = confidence >= 70 ||
        (classification == 'IMPERSONATION' && confidence >= 60) ||
        hasUssd ||
        hasOtpDemand;

    return DetectionResult(
      confidence: confidence,
      classification: classification,
      verdictState: verdictState,
      flags: flags,
      warnings: warnings,
      evidence: evidence,
      isScam: isScam,
      shouldNotify: shouldNotify,
      senderType: senderType,
      claimedOrganization: claimedOrg,
      fraudType: fraudType,
      recommendedAction: recommendedAction ?? 'Be cautious with unverified senders.',
      hasSignalConflict: hasSignalConflict,
    );
  }
}
