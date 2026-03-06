import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/budget_entries_dao.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/data/repositories/budget_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetEntriesDao extends Mock implements BudgetEntriesDao {}

class MockTransactionsDao extends Mock implements TransactionsDao {}

BudgetEntryRow _row({
  String id = 'be1',
  String categoryId = 'c1',
  int month = 3,
  int year = 2026,
  int budgeted = 50000,
  int activity = -20000,
  int available = 30000,
}) => BudgetEntryRow(
  id: id,
  categoryId: categoryId,
  month: month,
  year: year,
  budgeted: budgeted,
  activity: activity,
  available: available,
);

const BudgetEntry model = BudgetEntry(
  id: 'be1',
  categoryId: 'c1',
  month: 3,
  year: 2026,
  budgeted: 50000,
  activity: -20000,
  available: 30000,
);

void main() {
  setUpAll(() => registerFallbackValue(const BudgetEntriesTableCompanion()));

  late MockBudgetEntriesDao dao;
  late MockTransactionsDao transactionsDao;
  late BudgetRepository repo;

  setUp(() {
    dao = MockBudgetEntriesDao();
    transactionsDao = MockTransactionsDao();
    repo = BudgetRepository(dao, transactionsDao);
  });

  group('BudgetRepository', () {
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
      when(() => dao.getById('be1')).thenAnswer((_) async => _row());

      expect(await repo.getById('be1'), model);
    });

    test('watchForMonth maps rows to domain models', () {
      when(
        () => dao.watchForMonth(3, 2026),
      ).thenAnswer((_) => Stream.value([_row()]));

      expect(repo.watchForMonth(3, 2026), emits([model]));
    });

    test('getOrCreate returns mapped model', () async {
      when(
        () => dao.getOrCreate('c1', 3, 2026),
      ).thenAnswer((_) async => _row());

      expect(await repo.getOrCreate('c1', 3, 2026), model);
    });

    test('save calls upsert with correct companion', () async {
      when(() => dao.upsert(any())).thenAnswer((_) async {});

      await repo.save(model);

      final captured =
          verify(() => dao.upsert(captureAny())).captured.single
              as BudgetEntriesTableCompanion;
      expect(captured.id.value, 'be1');
      expect(captured.categoryId.value, 'c1');
      expect(captured.month.value, 3);
      expect(captured.year.value, 2026);
      expect(captured.budgeted.value, 50000);
      expect(captured.activity.value, -20000);
      expect(captured.available.value, 30000);
    });

    test('updateAvailable delegates to DAO', () async {
      when(() => dao.updateAvailable(any(), any())).thenAnswer((_) async {});

      await repo.updateAvailable('be1', 40000);

      verify(() => dao.updateAvailable('be1', 40000)).called(1);
    });

    test('deleteById delegates to DAO', () async {
      when(() => dao.deleteById(any())).thenAnswer((_) async => 1);

      await repo.deleteById('be1');

      verify(() => dao.deleteById('be1')).called(1);
    });
  });
}
