import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockIAccountsRepository extends Mock implements IAccountsRepository {}

class _MockICategoryGroupsRepository extends Mock
    implements ICategoryGroupsRepository {}

class _MockICategoriesRepository extends Mock
    implements ICategoriesRepository {}

class _MockITransactionsRepository extends Mock
    implements ITransactionsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Transaction(
        id: 'fallback',
        accountId: 'a1',
        payee: 'Fallback',
        amount: -100,
        date: DateTime(2026).toUtc(),
        cleared: false,
        type: TransactionType.expense,
        updatedAt: DateTime(2026).toUtc(),
        isDeleted: false,
      ),
    );
  });

  group('TransactionFormBloc', () {
    late _MockIAccountsRepository accountsRepo;
    late _MockICategoryGroupsRepository groupsRepo;
    late _MockICategoriesRepository categoriesRepo;
    late _MockITransactionsRepository transactionsRepo;

    Transaction makeTransaction({
      String id = 't1',
      String accountId = 'a1',
      String? categoryId = 'cat1',
      int amount = -5000,
      bool cleared = false,
    }) => Transaction(
      id: id,
      accountId: accountId,
      categoryId: categoryId,
      payee: 'Test Payee',
      amount: amount,
      date: DateTime(2026, 1, 15).toUtc(),
      cleared: cleared,
      type: amount >= 0 ? TransactionType.income : TransactionType.expense,
      updatedAt: DateTime(2026, 1, 15).toUtc(),
      isDeleted: false,
    );

    Account makeAccount({String id = 'a1'}) => Account(
      id: id,
      name: 'Checking',
      type: AccountType.checking,
      balance: 100000,
      clearedBalance: 80000,
      currency: 'USD',
      onBudget: true,
    );

    CategoryGroup makeGroup({String id = 'g1'}) => CategoryGroup(
      id: id,
      name: 'Everyday',
      sortOrder: 0,
      isHidden: false,
    );

    Category makeCategory({String id = 'cat1', String groupId = 'g1'}) =>
        Category(id: id, groupId: groupId, name: 'Groceries', sortOrder: 0);

    setUp(() {
      accountsRepo = _MockIAccountsRepository();
      groupsRepo = _MockICategoryGroupsRepository();
      categoriesRepo = _MockICategoriesRepository();
      transactionsRepo = _MockITransactionsRepository();
    });

    tearDown(() {
      verifyNoMoreInteractions(accountsRepo);
      verifyNoMoreInteractions(groupsRepo);
      verifyNoMoreInteractions(categoriesRepo);
      verifyNoMoreInteractions(transactionsRepo);
    });

    TransactionFormBloc buildBloc() => TransactionFormBloc(
      accountsRepo,
      groupsRepo,
      categoriesRepo,
      transactionsRepo,
    );

    void stubReadyData() {
      when(() => accountsRepo.getAll())
          .thenAnswer((_) async => [makeAccount()]);
      when(() => groupsRepo.getAll())
          .thenAnswer((_) async => [makeGroup()]);
      when(() => categoriesRepo.getAll())
          .thenAnswer((_) async => [makeCategory()]);
    }

    // ---- Started (new transaction) ----------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Ready] when started for a new transaction',
      build: () {
        stubReadyData();
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TransactionFormStarted()),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>()
            .having((s) => s.accounts.length, 'accounts', 1)
            .having((s) => s.groups.length, 'groups', 1)
            .having((s) => s.categories.length, 'categories', 1)
            .having((s) => s.existing, 'existing', isNull),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
      },
    );

    // ---- Started with initialAccountId (UI hint — bloc ignores it) ----------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Ready] when started with initialAccountId (bloc ignores UI hint)',
      build: () {
        stubReadyData();
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const TransactionFormStarted(initialAccountId: 'a1')),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>()
            .having((s) => s.existing, 'existing', isNull),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
      },
    );

    // ---- Started (edit transaction) ---------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Ready(existing)] when started with transactionId',
      build: () {
        stubReadyData();
        when(() => transactionsRepo.getById('t1'))
            .thenAnswer((_) async => makeTransaction());
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const TransactionFormStarted(transactionId: 't1')),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>()
            .having((s) => s.existing, 'existing', isNotNull)
            .having((s) => s.existing?.id, 'existing.id', 't1'),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
        verify(() => transactionsRepo.getById('t1')).called(1);
      },
    );

    // ---- Started error ----------------------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Loading, Error] when data load fails',
      build: () {
        // Use thenAnswer with async throw so all three futures are started
        // before the exception propagates (matching Future.wait semantics).
        when(() => accountsRepo.getAll()).thenAnswer(
          (_) async => throw Exception('db error'),
        );
        when(() => groupsRepo.getAll())
            .thenAnswer((_) async => [makeGroup()]);
        when(() => categoriesRepo.getAll())
            .thenAnswer((_) async => [makeCategory()]);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const TransactionFormStarted()),
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormError>()
            .having((s) => s.message, 'message', contains('db error')),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
      },
    );

    // ---- Submitted (add) -------------------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits [Ready(submitting), Saved] when add succeeds',
      build: () {
        stubReadyData();
        when(() => transactionsRepo.addTransaction(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const TransactionFormStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(TransactionFormSubmitted(transaction: makeTransaction()));
      },
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          false,
        ),
        isA<TransactionFormReady>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          true,
        ),
        const TransactionFormSaved(),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
        verify(() => transactionsRepo.addTransaction(any())).called(1);
      },
    );

    // ---- Submitted (update) ----------------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'calls updateTransaction when editing an existing transaction',
      build: () {
        stubReadyData();
        when(() => transactionsRepo.getById('t1'))
            .thenAnswer((_) async => makeTransaction());
        when(() => transactionsRepo.updateTransaction(any()))
            .thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const TransactionFormStarted(transactionId: 't1'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(TransactionFormSubmitted(transaction: makeTransaction()));
      },
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>(),
        isA<TransactionFormReady>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          true,
        ),
        const TransactionFormSaved(),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
        verify(() => transactionsRepo.getById('t1')).called(1);
        verify(() => transactionsRepo.updateTransaction(any())).called(1);
      },
    );

    // ---- Submitted error -------------------------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'emits Ready(saveError) when addTransaction throws',
      build: () {
        stubReadyData();
        when(() => transactionsRepo.addTransaction(any())).thenAnswer(
          (_) async => throw Exception('write error'),
        );
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const TransactionFormStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(TransactionFormSubmitted(transaction: makeTransaction()));
      },
      expect: () => [
        const TransactionFormLoading(),
        isA<TransactionFormReady>().having(
          (s) => s.saveError,
          'saveError',
          isNull,
        ),
        isA<TransactionFormReady>().having(
          (s) => s.isSubmitting,
          'isSubmitting',
          true,
        ),
        isA<TransactionFormReady>()
            .having(
              (s) => s.saveError,
              'saveError',
              contains('write error'),
            )
            .having((s) => s.isSubmitting, 'isSubmitting', false),
      ],
      verify: (_) {
        verify(() => accountsRepo.getAll()).called(1);
        verify(() => groupsRepo.getAll()).called(1);
        verify(() => categoriesRepo.getAll()).called(1);
        verify(() => transactionsRepo.addTransaction(any())).called(1);
      },
    );

    // ---- Submitted ignored when not ready --------------------------------

    blocTest<TransactionFormBloc, TransactionFormState>(
      'ignores TransactionFormSubmitted when state is not Ready',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(TransactionFormSubmitted(transaction: makeTransaction())),
      expect: () => <TransactionFormState>[],
    );
  });
}
