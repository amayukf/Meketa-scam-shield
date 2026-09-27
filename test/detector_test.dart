import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/scam_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ethiopian SMS Scam & Impersonation Engine Tests', () {
    test('TEST 1: Personal sender impersonating Ethio Telecom (994 in body)', () async {
      const sender = '+251911223344';
      const message = '994 Dear customer, You have received voice from 1200 Birr monthly from Your amount 6000 Mint + 900 SMS and 25 GB MB will expire...';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(75));
      expect(result.classification, anyOf(equals('IMPERSONATION'), equals('LIKELY_SCAM')));
      expect(result.shouldNotify, isTrue);
      expect(result.claimedOrganization, equals('Ethio telecom'));
    });

    test('TEST 2: Personal sender with normal greeting', () async {
      const sender = '+251911223344';
      const message = 'Hello, how are you?';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, lessThan(40));
      expect(result.classification, anyOf(equals('NORMAL'), equals('SAFE')));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 3: Personal sender asking about class', () async {
      const sender = '+251911223344';
      const message = 'Are you coming to class tomorrow?';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, lessThan(40));
      expect(result.classification, anyOf(equals('NORMAL'), equals('SAFE')));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 4: Verified official sender (994) sending legitimate notification', () async {
      const sender = '251994';
      const message = 'Dear customer, your monthly voice package of 600 Minutes will expire in 2 days.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, lessThan(40));
      expect(result.classification, equals('LIKELY_OFFICIAL'));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 5: Personal sender requesting OTP for blocked telebirr account', () async {
      const sender = '+251911223344';
      const message = 'Your telebirr account is blocked. Send your OTP to this number to reactivate.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(75));
      expect(result.shouldNotify, isTrue);
    });

    test('TEST 6: Unknown sender claiming fake prize and requesting payment', () async {
      const sender = '0900000000';
      const message = 'You won 50,000 Birr. Pay 500 Birr registration fee to claim your prize.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(75));
      expect(result.shouldNotify, isTrue);
    });

    test('TEST 7: Unknown sender asking for a call', () async {
      const sender = '+251912345678';
      const message = 'Hi, can you call me?';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, lessThan(40));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 8: Verified official telebirr sender (127) sending legitimate OTP', () async {
      const sender = '127';
      const message = 'Your telebirr OTP is 849201. Valid for 5 minutes. Never share your OTP with anyone.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, lessThan(40));
      expect(result.classification, equals('LIKELY_OFFICIAL'));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 9: Verified official Awash Bank sender (AwashBank / 898) airtime purchase', () async {
      const sender = 'AwashBank';
      const message = 'Dear Customer, your account 0134*** has been debited by 100 ETB for Airtime purchase. Ref: AW987654321.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isFalse);
      expect(result.confidence, equals(0));
      expect(result.classification, equals('LIKELY_OFFICIAL'));
      expect(result.shouldNotify, isFalse);
    });

    test('TEST 10: Official sender (251994) sending phishing link', () async {
      const sender = '251994';
      const message = 'Dear customer, update your account immediately at http://telebirr-bonus.xyz to claim 1000 Birr.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(75));
      expect(result.flags, contains('Contains suspicious external web link'));
    });

    test('TEST 11: Official sender (127) asking recipient to reply with their OTP', () async {
      const sender = '127';
      const message = 'Your account is blocked. Send your OTP to 0911223344 to unblock.';

      final result = await ScamDetector.analyze(message, sender);

      expect(result.isScam, isTrue);
      expect(result.confidence, greaterThanOrEqualTo(75));
    });
  });
}
