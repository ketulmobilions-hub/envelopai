import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIBudgetRepository extends Mock implements IBudgetRepository {}

class MockICategoryGroupsRepository extends Mock
    implements ICategoryGroupsRepository {}

class MockICategoriesRepository extends Mock implements ICategoriesRepository {}

void main() {
  group('BudgetBloc', () {
    late MockIBudgetRepository budgetRepo;
    late MockICategoryGroupsRepository groupsRepo;
    late MockICategoriesRepository categoriesRepo;

    setUp(() {
      budgetRepo = MockIBudgetRepository();
      groupsRepo = MockICategoryGroupsRepository();
      categoriesRepo = MockICategoriesRepository();
    });

    tearDown(() {
      verifyNoMoreInteractions(budgetRepo);
      verifyNoMoreInteractions(groupsRepo);
      verifyNoMoreInteractions(categoriesRepo);
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

    CategoryGroup makeGroup({
      String id = 'g1',
      String name = 'Fixed Bills',
      int sortOrder = 0,
    }) => CategoryGroup(
          id: id,
          name: name,
          sortOrder: sortOrder,
          isHidden: false,
        );

    Category makeCategory({
      String id = 'c1',
      String groupId = 'g1',
      String name = 'Rent',
      int sortOrder = 0,
    }) => Category(id: id, groupId: groupId, name: name, sortOrder: sortOrder);

    void stubAll({
      ({List<BudgetEntry> entries, int tbb})? summary,
      List<CategoryGroup>? groups,
      List<Category>? categories,
      int month = 3,
      int year = 2026,
    }) {
      when(
        () => budgetRepo.watchMonthSummary(month, year),
      ).thenAnswer(
        (_) => Stream.value(
          summary ?? (entries: [makeEntry()], tbb: 5000),
        ),
      );
      when(
        () => groupsRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(groups ?? [makeGroup()]));
      when(
        () => categoriesRepo.watchAll(),
      ).thenAnswer((_) => Stream.value(categories ?? [makeCategory()]));
    }

    BudgetBloc buildBloc() =>
        BudgetBloc(budgetRepo, groupsRepo, categoriesRepo);

    blocTest<BudgetBloc, BudgetState>(
      'emits [BudgetLoading, BudgetLoaded] when BudgetMonthChanged is added',
      build: () {
        stubAll();
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>()
            .having((s) => s.tbb, 'tbb', 5000)
            .having((s) => s.month, 'month', 3)
            .having((s) => s.year, 'year', 2026)
            .having((s) => s.groups, 'groups', [makeGroup()])
            .having((s) => s.categories, 'categories', [makeCategory()]),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'tbb is forwarded from watchMonthSummary',
      build: () {
        stubAll(summary: (entries: [], tbb: -2000));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>().having((s) => s.tbb, 'tbb', -2000),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when budget repository throws',
      build: () {
        when(
          () => budgetRepo.watchMonthSummary(any(), any()),
        ).thenAnswer((_) => Stream.error(Exception('db error')));
        when(() => groupsRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        when(() => categoriesRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [
        const BudgetLoading(),
        isA<BudgetError>().having(
          (s) => s.message,
          'message',
          contains('db error'),
        ),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'restartable: second BudgetMonthChanged cancels first',
      build: () {
        // Month 3: stream never emits — proves it is cancelled.
        final controller = StreamController<
            ({List<BudgetEntry> entries, int tbb})>();
        when(
          () => budgetRepo.watchMonthSummary(3, 2026),
        ).thenAnswer((_) => controller.stream);
        when(
          () => budgetRepo.watchMonthSummary(4, 2026),
        ).thenAnswer(
          (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
        );
        when(() => groupsRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        when(() => categoriesRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const BudgetMonthChanged(month: 4, year: 2026));
      },
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>().having((s) => s.month, 'month', 4),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(4, 2026)).called(1);
        // watchAll is called twice: once before cancellation (month 3) and
        // once after restart (month 4).
        verify(() => groupsRepo.watchAll()).called(2);
        verify(() => categoriesRepo.watchAll()).called(2);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetEntryAllocated calls repository.allocate with correct args',
      build: () {
        stubAll();
        when(
          () => budgetRepo.allocate('c1', 3, 2026, 20000),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BudgetEntryAllocated(
            categoryId: 'c1',
            month: 3,
            year: 2026,
            budgeted: 20000,
          ),
        );
      },
      // No extra state emitted — stream re-emits automatically.
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>(),
      ],
      verify: (_) {
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
        verify(() => budgetRepo.allocate('c1', 3, 2026, 20000)).called(1);
      },
    );
  });
}
