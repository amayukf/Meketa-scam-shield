import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/scam_detector.dart';
import 'package:scam_shield/models/scam_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('False-Positive Shield & Legitimate Messages', () {
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

    test('Personal sender asking about class is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Are you coming to class tomorrow?',
        '+251911223344',
      );
      expect(res.isScam, isFalse);
      expect(res.confidence, lessThan(40));
      expect(res.classification, anyOf(equals('NORMAL'), equals('SAFE')));
      expect(res.shouldNotify, isFalse);
    });

    test('Unknown sender asking for a call is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Hi, can you call me?',
        '+251912345678',
      );
      expect(res.isScam, isFalse);
      expect(res.confidence, lessThan(40));
      expect(res.shouldNotify, isFalse);
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

    test('Verified official sender (994) sending legitimate notification is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Dear customer, your monthly voice package of 600 Minutes will expire in 2 days.',
        '251994',
      );
      expect(res.isScam, isFalse);
      expect(res.confidence, lessThan(40));
      expect(res.classification, equals('LIKELY_OFFICIAL'));
      expect(res.shouldNotify, isFalse);
    });

    test('Verified official Awash Bank sender (AwashBank / 898) airtime purchase is SAFE', () async {
      final res = await ScamDetector.analyze(
        'Dear Customer, your account 0134*** has been debited by 100 ETB for Airtime purchase. Ref: AW987654321.',
        'AwashBank',
      );
      expect(res.isScam, isFalse);
      expect(res.confidence, equals(0));
      expect(res.classification, equals('LIKELY_OFFICIAL'));
      expect(res.shouldNotify, isFalse);
    });
  });

  group('High-Risk Threat Detections & Impersonation', () {
    test('Personal sender impersonating Ethio Telecom (994 in body) is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        '994 Dear customer, You have received voice from 1200 Birr monthly from Your amount 6000 Mint + 900 SMS and 25 GB MB will expire...',
        '+251911223344',
      );
      expect(res.isScam, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(75));
      expect(res.classification, anyOf(equals('IMPERSONATION'), equals('LIKELY_SCAM'), equals('HIGH_RISK')));
      expect(res.shouldNotify, isTrue);
      expect(res.claimedOrganization, equals('Ethio telecom'));
    });

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

    test('Personal sender requesting OTP for blocked telebirr account is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Your telebirr account is blocked. Send your OTP to this number to reactivate.',
        '+251911223344',
      );
      expect(res.isScam, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(75));
      expect(res.shouldNotify, isTrue);
    });

    test('Unknown sender claiming fake prize and requesting payment is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'You won 50,000 Birr. Pay 500 Birr registration fee to claim your prize.',
        '0900000000',
      );
      expect(res.isScam, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(75));
      expect(res.shouldNotify, isTrue);
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

    test('Official sender (251994) sending phishing link is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Dear customer, update your account immediately at http://telebirr-bonus.xyz to claim 1000 Birr.',
        '251994',
      );
      expect(res.isScam, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(75));
      expect(res.flags, contains('Contains suspicious external web link'));
    });

    test('Official sender (127) asking recipient to reply with their OTP is HIGH_RISK', () async {
      final res = await ScamDetector.analyze(
        'Your account is blocked. Send your OTP to 0911223344 to unblock.',
        '127',
      );
      expect(res.isScam, isTrue);
      expect(res.confidence, greaterThanOrEqualTo(75));
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
