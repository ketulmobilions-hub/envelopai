import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockTransactionFormBloc
    extends MockBloc<TransactionFormEvent, TransactionFormState>
    implements TransactionFormBloc {}

// ---------------------------------------------------------------------------
// Helpers (const fixtures at file scope — true compile-time constants)
// ---------------------------------------------------------------------------

const _account = Account(
  id: 'a1',
  name: 'Checking',
  type: AccountType.checking,
  balance: 100000,
  clearedBalance: 80000,
  currency: 'USD',
  onBudget: true,
);

const _group = CategoryGroup(
  id: 'g1',
  name: 'Everyday',
  sortOrder: 0,
  isHidden: false,
);

const _category = Category(
  id: 'cat1',
  groupId: 'g1',
  name: 'Groceries',
  sortOrder: 0,
);

/// Wraps the given [bloc] in a minimal widget tree that reflects the
/// current bloc state without instantiating AddEditTransactionScreen
/// (which would call getIt and hit DI setup issues in tests).
Widget _wrapState(_MockTransactionFormBloc bloc) => MaterialApp(
  home: BlocProvider<TransactionFormBloc>.value(
    value: bloc,
    child: Scaffold(
      body: BlocBuilder<TransactionFormBloc, TransactionFormState>(
        builder: (context, state) => switch (state) {
          TransactionFormInitial() ||
          TransactionFormLoading() => const CircularProgressIndicator(),
          TransactionFormError(:final message) => Text(message),
          TransactionFormReady(:final accounts) =>
            Text('ready:${accounts.length}'),
          TransactionFormSaved() => const Text('saved'),
        },
      ),
    ),
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const TransactionFormStarted(),
    );
    registerFallbackValue(
      TransactionFormSubmitted(
        transaction: Transaction(
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
      ),
    );
  });

  group('TransactionFormState display', () {
    late _MockTransactionFormBloc bloc;

    // Helper factory declared inside the group block per project convention.
    TransactionFormReady readyState({Transaction? existing}) =>
        TransactionFormReady(
          accounts: const [_account],
          groups: const [_group],
          categories: const [_category],
          existing: existing,
        );

    setUp(() => bloc = _MockTransactionFormBloc());

    testWidgets('shows spinner when state is Loading', (tester) async {
      when(() => bloc.state).thenReturn(const TransactionFormLoading());
      await tester.pumpWidget(_wrapState(bloc));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error text when state is Error', (tester) async {
      when(() => bloc.state).thenReturn(
        const TransactionFormError(message: 'Something went wrong'),
      );
      await tester.pumpWidget(_wrapState(bloc));
      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows account count when state is Ready', (tester) async {
      when(() => bloc.state).thenReturn(readyState());
      await tester.pumpWidget(_wrapState(bloc));
      expect(find.text('ready:1'), findsOneWidget);
    });

    test('existing transaction is accessible from Ready state', () {
      final txn = Transaction(
        id: 't1',
        accountId: 'a1',
        categoryId: 'cat1',
        payee: 'Existing Payee',
        amount: -2500,
        date: DateTime(2026, 1, 15).toUtc(),
        cleared: true,
        type: TransactionType.expense,
        updatedAt: DateTime(2026, 1, 15).toUtc(),
        isDeleted: false,
      );
      final state = readyState(existing: txn);
      expect(state.existing?.id, 't1');
      expect(state.existing?.payee, 'Existing Payee');
      expect(state.existing?.amount, -2500);
    });

    testWidgets('shows saved text when state is Saved', (tester) async {
      when(() => bloc.state).thenReturn(const TransactionFormSaved());
      await tester.pumpWidget(_wrapState(bloc));
      expect(find.text('saved'), findsOneWidget);
    });
  });
}
