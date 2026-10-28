import 'package:flutter_test/flutter_test.dart';
import 'package:futuer_controller/main.dart';

void main() {
  testWidgets('Futuer Controller smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FutuerControllerApp());
    expect(find.byType(FutuerControllerApp), findsOneWidget);
  });
}
