import 'package:drift/drift.dart';

/// All primary keys are TEXT (UUID strings).

@DataClassName('AccountRow')
class AccountsTable extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get name => text()();

  /// 'checking' | 'savings' | 'creditCard' | 'cash'
  TextColumn get type => text()();

  /// Balance in minor currency units (e.g. cents).
  IntColumn get balance => integer()();

  /// Cleared balance in minor currency units.
  IntColumn get clearedBalance => integer()();

  TextColumn get currency => text().withDefault(const Constant('USD'))();
  BoolColumn get onBudget => boolean().withDefault(const Constant(true))();

  /// Unix milliseconds UTC — set when the account is successfully reconciled.
  IntColumn get lastReconciledAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryGroupRow')
class CategoryGroupsTable extends Table {
  @override
  String get tableName => 'category_groups';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CategoryRow')
class CategoriesTable extends Table {
  @override
  String get tableName => 'categories';

  TextColumn get id => text()();
  TextColumn get groupId => text().references(CategoryGroupsTable, #id)();
  TextColumn get name => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();

  /// Soft pointer to a Goal — resolved at the app layer, not a hard FK,
  /// to avoid a circular cascade between CategoriesTable and GoalsTable.
  TextColumn get goalId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BudgetEntryRow')
class BudgetEntriesTable extends Table {
  @override
  String get tableName => 'budget_entries';

  TextColumn get id => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();

  /// 1–12
  IntColumn get month => integer()();
  IntColumn get year => integer()();

  /// In minor currency units.
  IntColumn get budgeted => integer().withDefault(const Constant(0))();
  IntColumn get activity => integer().withDefault(const Constant(0))();
  IntColumn get available => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  /// SQLite automatically creates a unique index for this constraint —
  /// no separate explicit index needed for this combination.
  @override
  List<Set<Column>> get uniqueKeys => [
    {categoryId, month, year},
  ];
}

@DataClassName('TransactionRow')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(AccountsTable, #id)();

  /// NULL for transfers.
  TextColumn get categoryId =>
      text().nullable().references(CategoriesTable, #id)();

  TextColumn get payee => text()();

  /// In minor currency units. Positive = inflow, negative = outflow.
  IntColumn get amount => integer()();

  /// Stored as Unix milliseconds UTC.
  IntColumn get date => integer()();

  TextColumn get memo => text().nullable()();
  BoolColumn get cleared => boolean().withDefault(const Constant(false))();

  /// 'income' | 'expense' | 'transfer'
  TextColumn get type => text()();

  /// Links the two legs of a transfer.
  TextColumn get transferPairId => text().nullable()();

  /// Unix milliseconds UTC — used by sync conflict resolution.
  IntColumn get updatedAt => integer()();

  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Defined now for Phase 5. Not wired to DAOs until then.
@DataClassName('GoalRow')
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';

  TextColumn get id => text()();
  TextColumn get categoryId => text().references(CategoriesTable, #id)();

  /// 'targetBalance' | 'monthlyContribution' | 'byDate' | 'weekly'
  TextColumn get type => text()();

  /// Target amount in minor currency units. Must be > 0.
  IntColumn get targetAmount =>
      integer().customConstraint('NOT NULL CHECK (target_amount > 0)')();

  /// Optional target date stored as Unix milliseconds UTC, consistent with
  /// other date fields in the schema.
  IntColumn get targetDate => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
