import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:livefit/main.dart';

void main() {
  testWidgets('auth screen shows login and can switch to create account', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('LiveFit'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);

    final createAccountButton = find.byWidgetPredicate(
      (widget) =>
          widget is TextButton &&
          widget.child is Text &&
          (widget.child as Text).data == 'Create account',
    );

    await tester.ensureVisible(createAccountButton);
    await tester.tap(createAccountButton);
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Create Account'), findsNWidgets(2));
  });
}
