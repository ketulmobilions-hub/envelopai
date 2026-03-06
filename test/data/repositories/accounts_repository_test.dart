import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/accounts_dao.dart';
import 'package:envelope/data/repositories/accounts_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAccountsDao extends Mock implements AccountsDao {}

// Reusable fixtures
AccountRow _row({
  String id = 'a1',
  String name = 'Checking',
  String type = 'checking',
  int balance = 1000,
  int clearedBalance = 900,
  String currency = 'USD',
  bool onBudget = true,
}) => AccountRow(
  id: id,
  name: name,
  type: type,
  balance: balance,
  clearedBalance: clearedBalance,
  currency: currency,
  onBudget: onBudget,
);

const Account model = Account(
  id: 'a1',
  name: 'Checking',
  type: AccountType.checking,
  balance: 1000,
  clearedBalance: 900,
  currency: 'USD',
  onBudget: true,
);

void main() {
  setUpAll(() => registerFallbackValue(const AccountsTableCompanion()));

  late MockAccountsDao dao;
  late AccountsRepository repo;

  setUp(() {
    dao = MockAccountsDao();
    repo = AccountsRepository(dao);
  });

  group('AccountsRepository', () {
    test('watchAll maps rows to domain models', () {
      when(() => dao.watchAll()).thenAnswer((_) => Stream.value([_row()]));

      expect(
        repo.watchAll(),
        emits([model]),
      );
    });

    test('getAll maps rows to domain models', () async {
      when(() => dao.getAll()).thenAnswer((_) async => [_row()]);

      final result = await repo.getAll();

      expect(result, [model]);
    });

    test('getById returns null when DAO returns null', () async {
      when(() => dao.getById(any())).thenAnswer((_) async => null);

      expect(await repo.getById('no-such'), isNull);
    });

    test('getById returns mapped model', () async {
      when(() => dao.getById('a1')).thenAnswer((_) async => _row());

      expect(await repo.getById('a1'), model);
    });

    test('save calls upsert with correct companion', () async {
      when(() => dao.upsert(any())).thenAnswer((_) async {});

      await repo.save(model);

      final captured =
          verify(() => dao.upsert(captureAny())).captured.single
              as AccountsTableCompanion;
      expect(captured.id.value, 'a1');
      expect(captured.name.value, 'Checking');
      expect(captured.type.value, 'checking');
      expect(captured.balance.value, 1000);
      expect(captured.clearedBalance.value, 900);
      expect(captured.currency.value, 'USD');
      expect(captured.onBudget.value, isTrue);
    });

    test('deleteById delegates to DAO', () async {
      when(() => dao.deleteById(any())).thenAnswer((_) async => 1);

      await repo.deleteById('a1');

      verify(() => dao.deleteById('a1')).called(1);
    });
  });
}
