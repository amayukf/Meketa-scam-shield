import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/models/scam_model.dart';
import 'package:scam_shield/services/forensic_service.dart';

void main() {
  group('ForensicService Tests', () {
    final sampleAlert = ScamModel(
      sender: '0911223344',
      senderType: SenderType.personal,
      message: 'ውድ ደንበኛችን የ 2,500 ብር የቴሌብር እድለኛ ሆነዋል። OTP ኮዱን ይላኩ።',
      confidence: 88,
      classification: 'HIGH_RISK',
      verdictState: VerdictState.highRisk,
      flags: ['Personal mobile number', 'Demands OTP credential'],
      warnings: ['Never share OTP'],
      evidence: [],
      isScam: true,
      timestamp: DateTime(2026, 10, 5, 14, 30),
    );

    test('Generates valid Case ID adhering to INSA standard', () {
      final report = ForensicService.generateReport(sampleAlert);
      expect(report.caseId, startsWith('INSA-ETH-'));
      expect(report.caseId.length, greaterThan(12));
    });

    test('Computes deterministic 64-character SHA-256 digest', () {
      final report = ForensicService.generateReport(sampleAlert);
      expect(report.sha256Fingerprint.length, equals(64));
      expect(RegExp(r'^[a-f0-9]{64}$').hasMatch(report.sha256Fingerprint), isTrue);
    });

    test('Accurately identifies national GSM carrier from prefix', () {
      final ethioReport = ForensicService.generateReport(sampleAlert);
      expect(ethioReport.senderCarrier, contains('Ethio Telecom'));

      final safaricomAlert = sampleAlert.copyWith(sender: '0712345678');
      final safaricomReport = ForensicService.generateReport(safaricomAlert);
      expect(safaricomReport.senderCarrier, contains('Safaricom'));

      final shortcodeAlert = sampleAlert.copyWith(sender: '994');
      final shortcodeReport = ForensicService.generateReport(shortcodeAlert);
      expect(shortcodeReport.senderCarrier, contains('Shortcode'));
    });

    test('Formats full court-admissible dossier text with integrity seals', () {
      final report = ForensicService.generateReport(sampleAlert);
      final text = report.toFormalDossierText();

      expect(text, contains('INFORMATION NETWORK SECURITY AGENCY (INSA) STANDARDS'));
      expect(text, contains(report.caseId));
      expect(text, contains(report.sha256Fingerprint));
      expect(text, contains('CHAIN OF CUSTODY'));
      expect(text, contains('CONFIDENTIAL & TAMPER-EVIDENT'));
    });
  });
}
