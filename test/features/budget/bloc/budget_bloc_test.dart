import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockIBudgetRepository extends Mock implements IBudgetRepository {}

class MockICategoryGroupsRepository extends Mock
    implements ICategoryGroupsRepository {}

class MockICategoriesRepository extends Mock implements ICategoriesRepository {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('BudgetBloc', () {
    late MockIBudgetRepository budgetRepo;
    late MockICategoryGroupsRepository groupsRepo;
    late MockICategoriesRepository categoriesRepo;
    late MockSharedPreferences prefs;

    setUp(() {
      budgetRepo = MockIBudgetRepository();
      groupsRepo = MockICategoryGroupsRepository();
      categoriesRepo = MockICategoriesRepository();
      prefs = MockSharedPreferences();
      // Default: no month has been rolled over yet.
      when(() => prefs.getBool(any())).thenReturn(false);
      when(() => prefs.setBool(any(), any())).thenAnswer((_) async => true);
    });

    tearDown(() {
      verifyNoMoreInteractions(budgetRepo);
      verifyNoMoreInteractions(groupsRepo);
      verifyNoMoreInteractions(categoriesRepo);
      verifyNoMoreInteractions(prefs);
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
        () => budgetRepo.rolloverMonth(any(), any()),
      ).thenAnswer((_) async {});
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
        BudgetBloc(budgetRepo, groupsRepo, categoriesRepo, prefs);

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
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
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
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'emits BudgetError when budget repository throws',
      build: () {
        when(
          () => budgetRepo.rolloverMonth(any(), any()),
        ).thenAnswer((_) async {});
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
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
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
          () => budgetRepo.rolloverMonth(any(), any()),
        ).thenAnswer((_) async {});
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
        // rolloverMonth is called for both month 3 (before cancellation
        // completes its await) and month 4.
        verify(
          () => budgetRepo.rolloverMonth(any(), any()),
        ).called(greaterThanOrEqualTo(1));
        // prefs interactions for both months are intentionally verified with
        // a lenient matcher because the cancellation point of the month-3
        // handler is non-deterministic — it may or may not complete its
        // setBool before the restartable transformer kills the emitter.
        verify(() => prefs.getBool(any())).called(greaterThanOrEqualTo(1));
        verify(
          () => prefs.setBool(any(), any()),
        ).called(greaterThanOrEqualTo(1));
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
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
        verify(() => budgetRepo.allocate('c1', 3, 2026, 20000)).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetMoneyMoved calls repository.moveMoney with correct args',
      build: () {
        stubAll();
        when(
          () => budgetRepo.moveMoney('c1', 'c2', 3, 2026, 10000),
        ).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const BudgetMoneyMoved(
            fromCategoryId: 'c1',
            toCategoryId: 'c2',
            month: 3,
            year: 2026,
            amount: 10000,
          ),
        );
      },
      // No extra state emitted — stream re-emits automatically.
      expect: () => [
        const BudgetLoading(),
        isA<BudgetLoaded>(),
      ],
      verify: (_) {
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
        verify(() => budgetRepo.moveMoney('c1', 'c2', 3, 2026, 10000))
            .called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetMoneyMoved is ignored when month/year does not match current state',
      build: () {
        stubAll();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        await Future<void>.delayed(Duration.zero);
        // Stale event — different month.
        bloc.add(
          const BudgetMoneyMoved(
            fromCategoryId: 'c1',
            toCategoryId: 'c2',
            month: 4,
            year: 2026,
            amount: 5000,
          ),
        );
      },
      expect: () => [const BudgetLoading(), isA<BudgetLoaded>()],
      verify: (_) {
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
        // moveMoney must NOT be called for the stale event.
        verifyNever(
          () => budgetRepo.moveMoney(any(), any(), any(), any(), any()),
        );
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'BudgetEntryAllocated is ignored when month/year does not match '
      'current state',
      build: () {
        stubAll();
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const BudgetMonthChanged(month: 3, year: 2026));
        await Future<void>.delayed(Duration.zero);
        // Stale event — different month.
        bloc.add(
          const BudgetEntryAllocated(
            categoryId: 'c1',
            month: 4,
            year: 2026,
            budgeted: 20000,
          ),
        );
      },
      expect: () => [const BudgetLoading(), isA<BudgetLoaded>()],
      verify: (_) {
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        verify(() => prefs.setBool('rollover_applied_2026_3', true)).called(1);
        verify(() => budgetRepo.rolloverMonth(2, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
        // allocate must NOT be called for the stale event.
        verifyNever(
          () => budgetRepo.allocate(any(), any(), any(), any()),
        );
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'rollover is skipped on second open of the same month',
      build: () {
        // Simulate that rollover for month 3/2026 was already applied.
        // Stubs are built manually (not via stubAll) so that rolloverMonth has
        // no registered answer — any accidental call will throw, making
        // verifyNever a belt-and-suspenders check rather than the only guard.
        when(
          () => prefs.getBool('rollover_applied_2026_3'),
        ).thenReturn(true);
        when(
          () => budgetRepo.watchMonthSummary(3, 2026),
        ).thenAnswer(
          (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
        );
        when(() => groupsRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        when(() => categoriesRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 3, year: 2026)),
      expect: () => [const BudgetLoading(), isA<BudgetLoaded>()],
      verify: (_) {
        verify(() => prefs.getBool('rollover_applied_2026_3')).called(1);
        // rolloverMonth must NOT be called — prefs flag is already set.
        verifyNever(() => budgetRepo.rolloverMonth(any(), any()));
        // setBool must NOT be called — rollover was skipped entirely.
        verifyNever(() => prefs.setBool(any(), any()));
        verify(() => budgetRepo.watchMonthSummary(3, 2026)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );

    blocTest<BudgetBloc, BudgetState>(
      'rollover wraps December → January correctly',
      build: () {
        when(
          () => budgetRepo.rolloverMonth(any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => budgetRepo.watchMonthSummary(1, 2027),
        ).thenAnswer(
          (_) => Stream.value((entries: <BudgetEntry>[], tbb: 0)),
        );
        when(() => groupsRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        when(() => categoriesRepo.watchAll())
            .thenAnswer((_) => Stream.value([]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const BudgetMonthChanged(month: 1, year: 2027)),
      expect: () => [const BudgetLoading(), isA<BudgetLoaded>()],
      verify: (_) {
        verify(() => prefs.getBool('rollover_applied_2027_1')).called(1);
        verify(() => prefs.setBool('rollover_applied_2027_1', true)).called(1);
        // Previous month of January 2027 is December 2026.
        verify(() => budgetRepo.rolloverMonth(12, 2026)).called(1);
        verify(() => budgetRepo.watchMonthSummary(1, 2027)).called(1);
        verify(() => groupsRepo.watchAll()).called(1);
        verify(() => categoriesRepo.watchAll()).called(1);
      },
    );
  });
}
