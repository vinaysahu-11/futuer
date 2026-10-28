import 'package:flutter_test/flutter_test.dart';
import 'package:futuer_agent/main.dart';

void main() {
  testWidgets('Futuer Agent smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FutuerAgentApp());
    expect(find.byType(FutuerAgentApp), findsOneWidget);
  });
}
