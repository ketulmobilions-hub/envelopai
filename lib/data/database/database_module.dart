import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/accounts_dao.dart';
import 'package:envelope/data/database/daos/budget_entries_dao.dart';
import 'package:envelope/data/database/daos/categories_dao.dart';
import 'package:envelope/data/database/daos/category_groups_dao.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:injectable/injectable.dart';

Future<void> closeDatabase(AppDatabase db) => db.close();

@module
abstract class DatabaseModule {
  @Singleton(dispose: closeDatabase)
  AppDatabase get appDatabase => AppDatabase();

  @LazySingleton()
  AccountsDao accountsDao(AppDatabase db) => db.accounts;

  @LazySingleton()
  CategoryGroupsDao categoryGroupsDao(AppDatabase db) => db.categoryGroups;

  @LazySingleton()
  CategoriesDao categoriesDao(AppDatabase db) => db.categories;

  @LazySingleton()
  BudgetEntriesDao budgetEntriesDao(AppDatabase db) => db.budgetEntries;

  @LazySingleton()
  TransactionsDao transactionsDao(AppDatabase db) => db.transactions;
}
