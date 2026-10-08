import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/services/ussd_analyzer_service.dart';

void main() {
  group('UssdAnalyzerService Tests', () {
    test('Detects malicious airtime transfer code and extracts amount & phone', () {
      const attackCode = '*804*0911223344*50#';
      final result = UssdAnalyzerService.scan(attackCode);

      expect(result.isUssd, isTrue);
      expect(result.isDangerous, isTrue);
      expect(result.riskLevel, equals('CRITICAL'));
      expect(result.extractedAmount, equals('50 ETB'));
      expect(result.extractedTargetNumber, equals('0911223344'));
      expect(result.threatCategory, contains('Airtime Theft'));
    });

    test('Detects call forwarding OTP hijacking code', () {
      const attackCode = '*21*0911223344#';
      final result = UssdAnalyzerService.scan(attackCode);

      expect(result.isUssd, isTrue);
      expect(result.isDangerous, isTrue);
      expect(result.riskLevel, equals('CRITICAL'));
      expect(result.extractedTargetNumber, equals('0911223344'));
      expect(result.threatCategory, contains('Forwarding'));
      expect(result.mitigation, contains('##21#'));
    });

    test('Identifies call forwarding cancellation code as remedial and safe', () {
      const cancelCode = '##21#';
      final result = UssdAnalyzerService.scan(cancelCode);

      expect(result.isUssd, isTrue);
      expect(result.isDangerous, isFalse);
      expect(result.riskLevel, equals('SAFE'));
      expect(result.threatCategory, contains('Countermeasure'));
    });

    test('Identifies standard Ethio Telecom balance inquiry as safe', () {
      const balanceCode = '*804#';
      final result = UssdAnalyzerService.scan(balanceCode);

      expect(result.isUssd, isTrue);
      expect(result.isDangerous, isFalse);
      expect(result.riskLevel, equals('SAFE'));
    });
  });
}
