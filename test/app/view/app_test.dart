// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:envelope/app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('App', () {
    testWidgets('renders budget screen on launch', (tester) async {
      await tester.pumpWidget(App());
      await tester.pumpAndSettle();
      expect(find.text('Budget'), findsWidgets);
    });
  });
}
