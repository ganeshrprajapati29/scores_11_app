// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:scores11/main.dart';

void main() {
  testWidgets('Scores11 app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const Cric11App());
    expect(find.byType(Cric11App), findsOneWidget);
  });
}
