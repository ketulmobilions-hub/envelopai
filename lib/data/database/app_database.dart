import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:envelope/data/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AccountsTable,
    CategoryGroupsTable,
    CategoriesTable,
    BudgetEntriesTable,
    TransactionsTable,
    GoalsTable,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Increment this whenever the schema changes and add a migration step in
  /// [migration] below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Indexes for high-frequency query patterns.
      await customStatement(
        'CREATE INDEX idx_transactions_account_date '
        'ON transactions (account_id, date)',
      );
      await customStatement(
        'CREATE INDEX idx_transactions_category '
        'ON transactions (category_id)',
      );
      await customStatement(
        'CREATE INDEX idx_budget_entries_category '
        'ON budget_entries (category_id)',
      );
      await customStatement(
        'CREATE INDEX idx_categories_group '
        'ON categories (group_id)',
      );
      await customStatement(
        'CREATE INDEX idx_goals_category '
        'ON goals (category_id)',
      );
    },
    onUpgrade: (m, from, to) async {
      // Add migration steps here when schemaVersion is incremented.
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'envelope_db');
  }
}
