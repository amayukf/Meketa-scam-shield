class UssdScanResult {
  final bool isUssd;
  final bool isDangerous;
  final String rawCode;
  final String threatCategory;
  final String? extractedTargetNumber;
  final String? extractedAmount;
  final String riskLevel; // 'CRITICAL', 'HIGH', 'SAFE', 'INFO'
  final String explanationEn;
  final String explanationAm;
  final String mitigation;

  const UssdScanResult({
    required this.isUssd,
    required this.isDangerous,
    required this.rawCode,
    required this.threatCategory,
    this.extractedTargetNumber,
    this.extractedAmount,
    required this.riskLevel,
    required this.explanationEn,
    required this.explanationAm,
    required this.mitigation,
  });
}

class UssdAnalyzerService {
  /// Regular expressions for Ethiopian telecom USSD codes
  static final RegExp _ussdRegex = RegExp(r'\*[\d\*#]+#');

  // Airtime transfer: *804*09XXXXXXXX*amount# or *805*...
  static final RegExp _airtimeTransferRegex = RegExp(
    r'\*80[45]\*(\+?251\d{9}|09\d{8}|07\d{8})\*(\d+)#',
  );

  // Call forwarding: *21*number# or **21*number# or *61*...
  static final RegExp _callForwardingRegex = RegExp(
    r'\*{1,2}(21|61|62|67)\*(\+?251\d{9}|09\d{8}|07\d{8})#',
  );

  // Cancellation codes: ##21#, #21#, ##002#
  static final RegExp _cancelForwardingRegex = RegExp(
    r'#{1,2}(21|61|62|67|002)#',
  );

  /// Scan any string or input for concealed or explicit USSD strings
  static UssdScanResult scan(String text) {
    final clean = text.trim();
    final match = _ussdRegex.firstMatch(clean);
    final targetCode = match != null ? match.group(0)! : clean;

    if (!targetCode.startsWith('*') && !targetCode.startsWith('#')) {
      return const UssdScanResult(
        isUssd: false,
        isDangerous: false,
        rawCode: '',
        threatCategory: 'None',
        riskLevel: 'INFO',
        explanationEn: 'No telecom USSD sequence detected.',
        explanationAm: 'ምንም የ USSD ኮድ አልተገኘም።',
        mitigation: 'Enter a valid code starting with * and ending with # (e.g. *804*0911223344*50#).',
      );
    }

    // 1. Airtime Transfer Scam Check
    final airtimeMatch = _airtimeTransferRegex.firstMatch(targetCode);
    if (airtimeMatch != null) {
      final phone = airtimeMatch.group(1)!;
      final amount = airtimeMatch.group(2)!;
      return UssdScanResult(
        isUssd: true,
        isDangerous: true,
        rawCode: targetCode,
        threatCategory: 'Airtime Theft (Ethio Telecom Balance Drain)',
        extractedTargetNumber: phone,
        extractedAmount: '$amount ETB',
        riskLevel: 'CRITICAL',
        explanationEn:
            'MALICIOUS AIRTIME DRAIN: Dialing this USSD code will silently transfer $amount ETB from your Ethio Telecom balance to $phone.',
        explanationAm:
            'የአየር ሰዓት ማጭበርበር! ይህንን ኮድ መደወል $amount ብር ከአካውንትዎ ወደ $phone በስውር ያስተላልፋል።',
        mitigation: 'DO NOT DIAL THIS CODE. Delete the message immediately and block the sender.',
      );
    }

    // 2. Call / SMS Forwarding Hijacking Check
    final forwardMatch = _callForwardingRegex.firstMatch(targetCode);
    if (forwardMatch != null) {
      final prefix = forwardMatch.group(1)!;
      final phone = forwardMatch.group(2)!;
      return UssdScanResult(
        isUssd: true,
        isDangerous: true,
        rawCode: targetCode,
        threatCategory: 'Call & OTP Hijacking (Unconditional Forwarding)',
        extractedTargetNumber: phone,
        riskLevel: 'CRITICAL',
        explanationEn:
            'CRITICAL SECURITY TRAP: Dialing *$prefix* will divert all your incoming calls and voice OTP security codes to $phone. Scammers use this to hack bank accounts!',
        explanationAm:
            'አደገኛ ጥቃት! ይህ ኮድ የባንክ እና የቴሌብር OTP ጥሪዎችን ወደ አጭበርባሪው ($phone) እንዲዛወሩ ያደርጋል።',
        mitigation:
            'Never dial this. If you already dialed it, immediately dial ##21# or ##002# to cancel all forwardings.',
      );
    }

    // 3. Forwarding Cancellation Code
    if (_cancelForwardingRegex.hasMatch(targetCode)) {
      return UssdScanResult(
        isUssd: true,
        isDangerous: false,
        rawCode: targetCode,
        threatCategory: 'Security Countermeasure',
        riskLevel: 'SAFE',
        explanationEn:
            'REMEDIAL CODE: This code cancels active call forwarding rules on your SIM card.',
        explanationAm:
            'ይህ ኮድ በስልክዎ ላይ የተደረጉ የጥሪ ማስተላለፊያ (Call Forwarding) ህጎችን በሙሉ ይሰርዛል።',
        mitigation: 'Safe to dial if you suspect your calls/SMS have been redirected by a hacker.',
      );
    }

    // 4. Official Ethio Telecom Shortcodes
    if (targetCode == '*804#' || targetCode == '*999#' || targetCode == '*127#' || targetCode == '*805#') {
      return UssdScanResult(
        isUssd: true,
        isDangerous: false,
        rawCode: targetCode,
        threatCategory: 'Official Telecom Utility',
        riskLevel: 'SAFE',
        explanationEn: 'Official Ethio Telecom service code (Balance query, Telebirr, or package purchase).',
        explanationAm: 'ትክክለኛ የኢትዮ ቴሌኮም መደበኛ አገልግሎት ኮድ (ቀሪ ሂሳብ፣ ቴሌብር ወይም ፓኬጅ)።',
        mitigation: 'Normal utility code.',
      );
    }

    // 5. Unknown or Unclassified USSD string
    return UssdScanResult(
      isUssd: true,
      isDangerous: targetCode.contains('*') && targetCode.length > 6,
      rawCode: targetCode,
      threatCategory: 'Unclassified Custom USSD',
      riskLevel: 'HIGH',
      explanationEn: 'Unverified USSD string. Unknown parameters may trigger background SIM service requests.',
      explanationAm: 'ያልተረጋገጠ የ USSD ኮድ። ከማይታወቁ ሰዎች የተላኩ ኮዶችን አይደውሉ።',
      mitigation: 'Verify with Ethio Telecom (994) before dialing unfamiliar USSD strings.',
    );
  }
}
