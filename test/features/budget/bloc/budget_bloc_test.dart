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

  group('BudgetBloc', () {
    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when BudgetMonthChanged is added',
      build: () {
        when(
          () => budgetRepo.watchForMonth(3, 2026),
        ).thenAnswer((_) => Stream.value([makeEntry()]));
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        BudgetLoaded(entries: [makeEntry()], month: 3, year: 2026),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchForMonth(3, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] with empty list when no entries',
      build: () {
        when(
          () => budgetRepo.watchForMonth(1, 2026),
        ).thenAnswer((_) => Stream.value([]));
        return BudgetBloc(budgetRepo);
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 1, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        const BudgetLoaded(entries: [], month: 1, year: 2026),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchForMonth(1, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetError] when repository throws',
      build: () {
        when(
          () => budgetRepo.watchForMonth(any(), any()),
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
        verify(() => budgetRepo.watchForMonth(3, 2026)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'restartable: second BudgetMonthChanged cancels first and emits new '
      'month data',
      build: () {
        // First stream never emits — proves the handler is cancelled.
        final controller = StreamController<List<BudgetEntry>>();
        when(
          () => budgetRepo.watchForMonth(3, 2026),
        ).thenAnswer((_) => controller.stream);
        when(
          () => budgetRepo.watchForMonth(4, 2026),
        ).thenAnswer(
          (_) => Stream.value([makeEntry(id: 'e2', month: 4)]),
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
      // final state is BudgetLoaded for month 4 and that both streams were
      // subscribed to (verified below).
      expect: () => [
        const BudgetLoading(), // from month 4
        isA<BudgetLoaded>().having((s) => s.month, 'month', 4),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchForMonth(3, 2026)).called(1);
        verify(() => budgetRepo.watchForMonth(4, 2026)).called(1);
      },
    );
  });
}
