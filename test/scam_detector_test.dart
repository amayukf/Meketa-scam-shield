import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/scam_detector.dart';
import 'package:scam_shield/models/scam_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('False-Positive Shield (Legitimate & Conversational Messages)', () {
    test('Conversational greeting between personal contacts is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Selam bro, are we meeting at 4 PM for coffee?',
        '0912345678',
      );
      expect(res.verdictState, VerdictState.safe);
      expect(res.confidence, lessThan(20));
      expect(res.isScam, false);
      expect(res.evidence.any((e) => e.layerIndex == 3 && e.isMitigation), true);
    });

    test('Amharic friendly greeting is SAFE', () async {
      final res = await ScamDetector.analyze(
        'ሰላም እንዴት ነህ? ደህና ነሽ ወይ? ዛሬ እንገናኝ',
        '0911223344',
      );
      expect(res.verdictState, VerdictState.safe);
      expect(res.confidence, lessThan(20));
      expect(res.isScam, false);
    });

    test('Clean personal account number sharing is SAFE / LOW_RISK', () async {
      final res = await ScamDetector.analyze(
        'Acc number: 1000123456789 CBE Dawit Hailu',
        '0911223344',
      );
      expect(res.confidence, lessThan(30));
      expect(res.isScam, false);
    });

    test('Legitimate bank debit/credit notification from official shortcode is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Dear Dawit, your A/C 100012345678 has been credited by ETB 2,500.00. Txn ID: FT240824. Balance is ETB 14,350.00',
        '889',
      );
      expect(res.verdictState, VerdictState.safe);
      expect(res.confidence, lessThan(20));
      expect(res.isScam, false);
    });

    test('Legitimate OTP delivery notification from official shortcode is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Your Telebirr verification code is 482910. Do not share this code with anyone.',
        '127',
      );
      expect(res.verdictState, VerdictState.safe);
      expect(res.confidence, lessThan(20));
      expect(res.isScam, false);
    });
  });

  group('High-Risk Threat Detections', () {
    test('Personal number claiming bank transfer credit is HIGH_RISK impersonation', () async {
      final res = await ScamDetector.analyze(
        'Dear customer, your CBE account has been credited by 5,000 ETB from Abebe.',
        '0912345678',
      );
      expect(res.confidence, greaterThanOrEqualTo(70));
      expect(res.verdictState, VerdictState.highRisk);
      expect(res.isScam, true);
    });

    test('Demand to send/share OTP is HIGH_RISK credential theft', () async {
      final res = await ScamDetector.analyze(
        'Send the 6-digit OTP code you just received to confirm your prize.',
        '0911998877',
      );
      expect(res.confidence, greaterThanOrEqualTo(70));
      expect(res.verdictState, VerdictState.highRisk);
      expect(res.flags.any((f) => f.contains('OTP')), true);
    });

    test('Malicious USSD airtime transfer string is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Dial *806*0911223344*100# to activate free 10GB Ethio Telecom bundle.',
        '0912000000',
      );
      expect(res.confidence, greaterThanOrEqualTo(70));
      expect(res.verdictState, VerdictState.highRisk);
      expect(res.flags.any((f) => f.contains('USSD')), true);
    });

    test('Deceptive clone phishing domain is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Claim your Telebirr reward now: http://telebirr-bonus.xyz/claim',
        '0911000000',
      );
      expect(res.confidence, greaterThanOrEqualTo(70));
      expect(res.verdictState, VerdictState.highRisk);
    });
  });

  group('Signal Conflict & Boundary Handling', () {
    test('Official shortcode with malicious phishing link triggers CONFLICT / HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Your account is suspended. Verify immediately at http://telebirr-bonus.xyz',
        '127',
      );
      expect(res.hasSignalConflict, true);
      expect(res.confidence, greaterThanOrEqualTo(60));
    });

    test('Fake refund bait with urgency is SUSPICIOUS or HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'በስህተት 3000 ብር ልኬያለሁ፣ እባክህ አስቸኳይ መልስልኝ',
        '0911223344',
      );
      expect(res.confidence, greaterThanOrEqualTo(40));
      expect(res.verdictState != VerdictState.safe, true);
    });
  });
}
