import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/data/repositories/transactions_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsDao extends Mock implements TransactionsDao {}

final DateTime _date = DateTime.utc(2026, 3, 6);
final DateTime _updatedAt = DateTime.utc(2026, 3, 6);

TransactionRow _row({
  String id = 't1',
  String accountId = 'acc1',
  String? categoryId = 'c1',
  String payee = 'Store',
  int amount = -5000,
  String? memo,
  bool cleared = false,
  String type = 'expense',
  String? transferPairId,
  bool isDeleted = false,
}) => TransactionRow(
  id: id,
  accountId: accountId,
  categoryId: categoryId,
  payee: payee,
  amount: amount,
  date: _date.millisecondsSinceEpoch,
  memo: memo,
  cleared: cleared,
  type: type,
  transferPairId: transferPairId,
  updatedAt: _updatedAt.millisecondsSinceEpoch,
  isDeleted: isDeleted,
);

Transaction get model => Transaction(
  id: 't1',
  accountId: 'acc1',
  categoryId: 'c1',
  payee: 'Store',
  amount: -5000,
  date: _date,
  cleared: false,
  type: TransactionType.expense,
  updatedAt: _updatedAt,
  isDeleted: false,
);

void main() {
  setUpAll(() => registerFallbackValue(const TransactionsTableCompanion()));

  late MockTransactionsDao dao;
  late TransactionsRepository repo;

  setUp(() {
    dao = MockTransactionsDao();
    repo = TransactionsRepository(dao);
  });

  group('TransactionsRepository', () {
    test('watchAll maps rows to domain models', () {
      when(() => dao.watchAll()).thenAnswer((_) => Stream.value([_row()]));

      expect(repo.watchAll(), emits([model]));
    });

    test('getAll maps rows to domain models', () async {
      when(() => dao.getAll()).thenAnswer((_) async => [_row()]);

      expect(await repo.getAll(), [model]);
    });

    test('getById returns null when not found', () async {
      when(() => dao.getById(any())).thenAnswer((_) async => null);

      expect(await repo.getById('no-such'), isNull);
    });

    test('getById returns mapped model', () async {
      when(() => dao.getById('t1')).thenAnswer((_) async => _row());

      expect(await repo.getById('t1'), model);
    });

    test('watchByAccount maps rows to domain models', () {
      when(
        () => dao.watchByAccount('acc1'),
      ).thenAnswer((_) => Stream.value([_row()]));

      expect(repo.watchByAccount('acc1'), emits([model]));
    });

    test('save calls upsert with correct companion', () async {
      when(() => dao.upsert(any())).thenAnswer((_) async {});

      await repo.save(model);

      final captured =
          verify(() => dao.upsert(captureAny())).captured.single
              as TransactionsTableCompanion;
      expect(captured.id.value, 't1');
      expect(captured.accountId.value, 'acc1');
      expect(captured.categoryId.value, 'c1');
      expect(captured.payee.value, 'Store');
      expect(captured.amount.value, -5000);
      expect(captured.date.value, _date.millisecondsSinceEpoch);
      expect(captured.type.value, 'expense');
      expect(captured.isDeleted.value, isFalse);
    });

    test('softDelete delegates to DAO', () async {
      when(
        () => dao.softDelete(any(), updatedAtMs: any(named: 'updatedAtMs')),
      ).thenAnswer((_) async => 1);

      final result = await repo.softDelete(
        't1',
        updatedAtMs: _updatedAt.millisecondsSinceEpoch,
      );

      expect(result, 1);
      verify(
        () => dao.softDelete(
          't1',
          updatedAtMs: _updatedAt.millisecondsSinceEpoch,
        ),
      ).called(1);
    });
  });
}
