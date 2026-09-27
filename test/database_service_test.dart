import 'package:flutter_test/flutter_test.dart';
import 'package:scam_shield/models/scam_model.dart';
import 'package:scam_shield/services/database_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseService Tests', () {
    late DatabaseService dbService;

    setUp(() {
      dbService = DatabaseService.instance;
    });

    test('Empty database stats return zero counts', () async {
      final stats = await dbService.getStats();
      expect(stats, containsPair('totalScanned', 0));
      expect(stats, containsPair('scamsBlocked', 0));
      expect(stats, containsPair('blockRate', 0));
    });

    test('Insert alert and retrieve in getAllAlerts', () async {
      final alert = ScamModel(
        sender: '0911223344',
        senderType: SenderType.personal,
        message: 'Test scam message',
        confidence: 85,
        classification: 'HIGH_RISK',
        verdictState: VerdictState.highRisk,
        flags: ['Test flag'],
        warnings: [],
        evidence: [],
        isScam: true,
        timestamp: DateTime.now(),
      );

      final id = await dbService.insertAlert(alert);
      expect(id, greaterThan(0));

      final all = await dbService.getAllAlerts();
      expect(all.isNotEmpty, true);
      expect(all.first.sender, equals('0911223344'));
      expect(all.first.confidence, equals(85));
    });

    test('Update alert feedback updates stored values', () async {
      final all = await dbService.getAllAlerts();
      if (all.isNotEmpty) {
        final target = all.first;
        final updated = target.copyWith(
          userFeedback: 'marked_safe',
          confidence: 20,
          isScam: false,
          verdictState: VerdictState.safe,
        );

        final rows = await dbService.updateAlert(updated);
        expect(rows, greaterThanOrEqualTo(1));

        final reFetched = await dbService.getAllAlerts();
        final match = reFetched.firstWhere((a) => a.id == target.id);
        expect(match.userFeedback, equals('marked_safe'));
        expect(match.confidence, equals(20));
      }
    });

    test('Reference check detects duplicate receipt numbers', () async {
      const ref = 'DHB6P39JIC';
      final check1 = await dbService.checkAndRecordReference(ref);
      expect(check1['isDuplicate'], isFalse);

      final check2 = await dbService.checkAndRecordReference(ref);
      expect(check2['isDuplicate'], isTrue);
      expect(check2['timesChecked'], greaterThanOrEqualTo(2));
    });

    test('Delete alert removes item from storage', () async {
      final all = await dbService.getAllAlerts();
      if (all.isNotEmpty) {
        final idToDelete = all.first.id!;
        await dbService.deleteAlert(idToDelete);

        final remaining = await dbService.getAllAlerts();
        expect(remaining.any((a) => a.id == idToDelete), isFalse);
      }
    });
  });
}
