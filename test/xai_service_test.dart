import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/models/scam_model.dart';
import 'package:scam_shield/services/xai_service.dart';

void main() {
  group('XaiService Tests', () {
    test('Deconstructs high-risk alert into distinct feature attributions', () {
      final alert = ScamModel(
        sender: '0911223344',
        senderType: SenderType.personal,
        message: 'ውድ ደንበኛችን የቴሌብር አካውንትዎ በ 2 ሰዓት ውስጥ ይታገዳል። የላክነውን OTP ይላኩ።',
        confidence: 90,
        classification: 'HIGH_RISK',
        verdictState: VerdictState.highRisk,
        flags: ['Personal sender', 'OTP request'],
        warnings: [],
        evidence: [],
        isScam: true,
        timestamp: DateTime.now(),
      );

      final xai = XaiService.analyze(alert);
      expect(xai.finalConfidenceScore, equals(90));
      expect(xai.factors.isNotEmpty, isTrue);

      final hasOtpFactor = xai.factors.any((f) => f.featureName.contains('OTP'));
      expect(hasOtpFactor, isTrue);

      final hasUrgencyFactor = xai.factors.any((f) => f.featureName.contains('Urgency') || f.featureName.contains('Coercion'));
      expect(hasUrgencyFactor, isTrue);

      expect(xai.counterfactualExplanation, contains('Counterfactual'));
    });

    test('Identifies verified shortcode mitigation in feature factors', () {
      final safeAlert = ScamModel(
        sender: '994',
        senderType: SenderType.official,
        message: 'ውድ ደንበኛችን የ 1GB ፓኬጅ ግዢዎ በተሳካ ሁኔታ ተጠናቋል።',
        confidence: 5,
        classification: 'SAFE',
        verdictState: VerdictState.safe,
        flags: [],
        warnings: [],
        evidence: [],
        isScam: false,
        timestamp: DateTime.now(),
      );

      final xai = XaiService.analyze(safeAlert);
      final hasWhitelistFactor = xai.factors.any((f) => f.contributionScore < 0);
      expect(hasWhitelistFactor, isTrue);
    });
  });
}
