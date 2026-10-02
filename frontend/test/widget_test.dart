import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('LiveFitApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LiveFitApp());
    expect(find.byType(LiveFitApp), findsOneWidget);
  });
}
