import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIBudgetRepository extends Mock implements IBudgetRepository {}

void main() {
  late MockIBudgetRepository budgetRepo;

  setUp(() {
    budgetRepo = MockIBudgetRepository();
  });

  tearDown(() {
    verifyNoMoreInteractions(budgetRepo);
  });

  group('BudgetBloc', () {
    BudgetEntry makeEntry({
      String id = 'e1',
      String categoryId = 'c1',
      int month = 3,
      int year = 2026,
      int budgeted = 10000,
      int activity = 3000,
      int available = 7000,
    }) => BudgetEntry(
          id: id,
          categoryId: categoryId,
          month: month,
          year: year,
          budgeted: budgeted,
          activity: activity,
          available: available,
        );

    ({List<BudgetEntry> entries, int tbb}) makeSummary({
      List<BudgetEntry>? entries,
      int tbb = 5000,
    }) => (entries: entries ?? [makeEntry()], tbb: tbb);

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when BudgetMonthChanged is added',
      build: () {
        when(
          () => budgetRepo.watchMonthSummary(3, 2026),
        ).thenAnswer((_) => Stream.value(makeSummary()));
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(
          entries: [makeEntry()],
          tbb: 5000,
          month: 3,
          year: 2026,
        ),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'tbb is included in BudgetLoaded state',
      build: () {
        when(
          () => budgetRepo.watchMonthSummary(3, 2026),
        ).thenAnswer(
          (_) => Stream.value((entries: <BudgetEntry>[], tbb: -2000)),
        );
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>().having((s) => s.tbb, 'tbb', -2000),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] with empty list when no entries',
      build: () {
        when(
          () => budgetRepo.watchMonthSummary(1, 2026),
        ).thenAnswer(
          (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
        );
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 1, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        const BudgetLoaded(entries: [], tbb: 0, month: 1, year: 2026),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(1, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetError] when repository throws',
      build: () {
        when(
          () => budgetRepo.watchMonthSummary(any(), any()),
        ).thenAnswer(
          (_) => Stream.error(Exception('db error')),
        );
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        isA<BudgetError>(),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'restartable: second BudgetMonthChanged cancels first and emits new '
      'month data',
      build: () {
        // First stream never emits — proves the handler is cancelled.
        final controller =
            StreamController<({List<BudgetEntry> entries, int tbb})>();
        when(
          () => budgetRepo.watchMonthSummary(3, 2026),
        ).thenAnswer((_) => controller.stream);
        when(
          () => budgetRepo.watchMonthSummary(4, 2026),
        ).thenAnswer(
          (_) => Stream.value(
            (entries: [makeEntry(id: 'e2', month: 4)], tbb: 1000),
          ),
        );
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        // Small delay to let the first handler start before being cancelled.
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BudgetMonthChanged(month: 4, year: 2026));
      },
      // With restartable(), the month-3 handler may be cancelled before
      // emitting BudgetLoading. The observable postcondition is that the
      // final state is BudgetLoaded for month 4.
      expect: () => [
        const BudgetLoading(), // from month 4
        isA<BudgetLoaded>().having((s) => s.month, 'month', 4),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(4, 2026)).called(1);
      },
    );
  });
}
