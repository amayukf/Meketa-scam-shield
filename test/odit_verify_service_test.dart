import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/odit_verify_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OditVerifyService Tests', () {
    test('Valid Telebirr reference returns offline verified result when key is absent', () async {
      final res = await OditVerifyService.verify('CL98765432');
      expect(res.ok, isTrue);
      expect(res.providerKey, equals('Telebirr'));
      expect(res.receipt?['status'], equals('FORMAT_VALID_OFFLINE'));
    });

    test('Valid CBE reference returns offline verified result when key is absent', () async {
      final res = await OditVerifyService.verify('FT240824ABCD1234');
      expect(res.ok, isTrue);
      expect(res.providerKey.contains('Commercial Bank of Ethiopia'), isTrue);
      expect(res.receipt?['status'], equals('FORMAT_VALID_OFFLINE'));
    });

    test('Unrecognized reference format fails format check gracefully', () async {
      final res = await OditVerifyService.verify('INVALID_SHORT_XYZ');
      expect(res.ok, isFalse);
      expect(res.error, isNotNull);
    });

    test('Empty reference returns immediate validation error', () async {
      final res = await OditVerifyService.verify('   ');
      expect(res.ok, isFalse);
      expect(res.error, contains('Please enter a transaction reference'));
    });
  });
}
