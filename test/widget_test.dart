import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scam_shield/main.dart';
import 'package:scam_shield/providers/scam_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ScamProvider(),
        child: const ScamShieldApp(),
      ),
    );
    expect(find.byType(ScamShieldApp), findsOneWidget);
  });
}
