// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:envelope/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders', (tester) async {
      await tester.pumpWidget(App());
      expect(find.text('EnvelopAI'), findsOneWidget);
    });
  });
}
