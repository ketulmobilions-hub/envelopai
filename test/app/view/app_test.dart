// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:envelope/app/app.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:envelope/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIBudgetRepository extends Mock implements IBudgetRepository {}

void main() {
  group('App', () {
    late _MockIBudgetRepository mockBudgetRepo;

    setUp(() {
      mockBudgetRepo = _MockIBudgetRepository();
      when(() => mockBudgetRepo.watchMonthSummary(any(), any())).thenAnswer(
        (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
      );

      getIt
        ..registerFactory<IBudgetRepository>(() => mockBudgetRepo)
        ..registerFactory<BudgetBloc>(
          () => BudgetBloc(getIt<IBudgetRepository>()),
        );
    });

    tearDown(getIt.reset);

    testWidgets('renders budget screen on launch', (tester) async {
      await tester.pumpWidget(App());
      await tester.pumpAndSettle();
      // 'Budget' appears in the bottom navigation bar label.
      expect(find.text('Budget'), findsWidgets);
    });
  });
}
