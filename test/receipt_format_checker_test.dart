import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/receipt_format_checker.dart';

void main() {
  group('ReceiptFormatChecker Tests', () {
    test('Telebirr reference format check', () {
      final res = ReceiptFormatChecker.check('DHB6P39JIC');
      expect(res.provider, 'Telebirr');
      expect(res.formatValid, isTrue);
      expect(res.officialUrl,
          'https://transactioninfo.ethiotelecom.et/receipt/DHB6P39JIC');
    });

    test('Telebirr URL extraction check', () {
      final res = ReceiptFormatChecker.check(
          'https://transactioninfo.ethiotelecom.et/receipt/DHA9OL4DOD');
      expect(res.provider, 'Telebirr');
      expect(res.referenceNumber, 'DHA9OL4DOD');
      expect(res.formatValid, isTrue);
    });

    test('CBE reference format check', () {
      final res = ReceiptFormatChecker.check('FT240801123456');
      expect(res.provider, 'Commercial Bank of Ethiopia (CBE)');
      expect(res.formatValid, isTrue);
      expect(res.officialUrl, 'https://combanketh.et');
    });

    test('Unrecognized reference format check', () {
      final res = ReceiptFormatChecker.check('INVALID_123');
      expect(res.provider, 'Unrecognized');
      expect(res.formatValid, isFalse);
      expect(res.officialUrl, isNull);
    });
  });
}
