import 'package:bloc_test/bloc_test.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:envelope/features/accounts/accounts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIAccountsRepository extends Mock implements IAccountsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const Account(
        id: 'fallback',
        name: 'Fallback',
        type: AccountType.checking,
        balance: 0,
        clearedBalance: 0,
        currency: 'USD',
        onBudget: true,
      ),
    );
  });

  group('AccountsBloc', () {
    late MockIAccountsRepository repo;

    Account makeAccount({
      String id = 'a1',
      String name = 'Checking',
      AccountType type = AccountType.checking,
      int balance = 100000,
      int clearedBalance = 80000,
      bool onBudget = true,
    }) => Account(
          id: id,
          name: name,
          type: type,
          balance: balance,
          clearedBalance: clearedBalance,
          currency: 'USD',
          onBudget: onBudget,
        );

    setUp(() {
      repo = MockIAccountsRepository();
    });

    tearDown(() => verifyNoMoreInteractions(repo));

    AccountsBloc buildBloc() => AccountsBloc(repo);

    blocTest<AccountsBloc, AccountsState>(
      'emits [AccountsLoading, AccountsLoaded] when AccountsStarted is added',
      build: () {
        when(() => repo.watchAll()).thenAnswer(
          (_) => Stream.value([makeAccount()]),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AccountsStarted()),
      expect: () => [
        const AccountsLoading(),
        isA<AccountsLoaded>()
            .having((s) => s.accounts, 'accounts', [makeAccount()]),
      ],
      verify: (_) => verify(() => repo.watchAll()).called(1),
    );

    blocTest<AccountsBloc, AccountsState>(
      'emits AccountsError when watchAll throws',
      build: () {
        when(() => repo.watchAll())
            .thenAnswer((_) => Stream.error(Exception('db error')));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AccountsStarted()),
      expect: () => [
        const AccountsLoading(),
        isA<AccountsError>()
            .having((s) => s.message, 'message', contains('db error')),
      ],
      verify: (_) => verify(() => repo.watchAll()).called(1),
    );

    blocTest<AccountsBloc, AccountsState>(
      'AccountAdded calls repository.addAccount',
      build: () {
        when(() => repo.watchAll())
            .thenAnswer((_) => Stream.value([makeAccount()]));
        when(() => repo.addAccount(any())).thenAnswer((_) async {});
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const AccountsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(AccountAdded(account: makeAccount(id: 'a2', name: 'Savings')));
      },
      expect: () => [
        const AccountsLoading(),
        isA<AccountsLoaded>(),
      ],
      verify: (_) {
        verify(() => repo.watchAll()).called(1);
        verify(
          () => repo.addAccount(makeAccount(id: 'a2', name: 'Savings')),
        ).called(1);
      },
    );

    blocTest<AccountsBloc, AccountsState>(
      'AccountAdded emits AccountsError when addAccount throws',
      build: () {
        when(() => repo.watchAll())
            .thenAnswer((_) => Stream.value([makeAccount()]));
        when(() => repo.addAccount(any()))
            .thenThrow(Exception('write error'));
        return buildBloc();
      },
      act: (bloc) async {
        bloc.add(const AccountsStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(AccountAdded(account: makeAccount(id: 'a2')));
      },
      expect: () => [
        const AccountsLoading(),
        isA<AccountsLoaded>(),
        isA<AccountsError>()
            .having((s) => s.message, 'message', contains('write error')),
      ],
      verify: (_) {
        verify(() => repo.watchAll()).called(1);
        verify(() => repo.addAccount(any())).called(1);
      },
    );
  });

  group('AccountsLoaded', () {
    Account makeAccount({
      String id = 'a1',
      int balance = 50000,
      bool onBudget = true,
    }) => Account(
          id: id,
          name: 'Test',
          type: AccountType.checking,
          balance: balance,
          clearedBalance: balance,
          currency: 'USD',
          onBudget: onBudget,
        );

    test('netWorth sums only onBudget balances', () {
      final state = AccountsLoaded(
        accounts: [
          makeAccount(balance: 100000),
          makeAccount(id: 'a2'),
          makeAccount(id: 'a3', balance: 200000, onBudget: false),
        ],
      );
      expect(state.netWorth, 150000);
    });

    test('budgetAccounts returns only onBudget accounts', () {
      final on = makeAccount();
      final off = makeAccount(id: 'a2', onBudget: false);
      final state = AccountsLoaded(accounts: [on, off]);
      expect(state.budgetAccounts, [on]);
      expect(state.trackingAccounts, [off]);
    });

    test('netWorth is negative when liabilities exceed assets', () {
      final state = AccountsLoaded(
        accounts: [
          makeAccount(),
          makeAccount(id: 'a2', balance: -80000),
        ],
      );
      expect(state.netWorth, -30000);
    });
  });
}
