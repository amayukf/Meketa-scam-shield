import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/virustotal_service.dart';

void main() {
  group('VirusTotalService Heuristic Tests', () {
    test('Official domain is recognized as safe', () async {
      final res = await VirusTotalService.scanLink('https://telebirr.et');
      expect(res.isMalicious, isFalse);
      expect(res.verdict, contains('OFFICIAL'));
    });

    test('Fake typosquatting bank domain is flagged as dangerous', () async {
      final res =
          await VirusTotalService.scanLink('http://telebirr-bonus-gift.xyz');
      expect(res.isMalicious, isTrue);
      expect(res.detectedThreats.isNotEmpty, isTrue);
    });

    test('Suspicious high-risk TLD link is flagged', () async {
      final res =
          await VirusTotalService.scanLink('http://cbe-birr-verify.tk');
      expect(res.isMalicious, isTrue);
    });
  });
}
