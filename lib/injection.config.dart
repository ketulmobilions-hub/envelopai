// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:envelope/app/app_module.dart' as _i301;
import 'package:envelope/data/database/app_database.dart' as _i979;
import 'package:envelope/data/database/daos/accounts_dao.dart' as _i171;
import 'package:envelope/data/database/daos/budget_entries_dao.dart' as _i861;
import 'package:envelope/data/database/daos/categories_dao.dart' as _i261;
import 'package:envelope/data/database/daos/category_groups_dao.dart' as _i1034;
import 'package:envelope/data/database/daos/transactions_dao.dart' as _i268;
import 'package:envelope/data/database/database_module.dart' as _i342;
import 'package:envelope/data/repositories/accounts_repository.dart' as _i65;
import 'package:envelope/data/repositories/budget_repository.dart' as _i927;
import 'package:envelope/data/repositories/categories_repository.dart' as _i106;
import 'package:envelope/data/repositories/category_groups_repository.dart'
    as _i385;
import 'package:envelope/data/repositories/transactions_repository.dart'
    as _i228;
import 'package:envelope/data/seed/seed_service.dart' as _i1017;
import 'package:envelope/domain/repositories/repositories.dart' as _i112;
import 'package:envelope/features/budget/bloc/budget_bloc.dart' as _i485;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    final databaseModule = _$DatabaseModule();
    await gh.singletonAsync<_i460.SharedPreferences>(
      () => appModule.prefs,
      preResolve: true,
    );
    gh.singleton<_i979.AppDatabase>(
      () => databaseModule.appDatabase,
      dispose: _i342.closeDatabase,
    );
    gh.lazySingleton<_i171.AccountsDao>(
      () => databaseModule.accountsDao(gh<_i979.AppDatabase>()),
    );
    gh.lazySingleton<_i1034.CategoryGroupsDao>(
      () => databaseModule.categoryGroupsDao(gh<_i979.AppDatabase>()),
    );
    gh.lazySingleton<_i261.CategoriesDao>(
      () => databaseModule.categoriesDao(gh<_i979.AppDatabase>()),
    );
    gh.lazySingleton<_i861.BudgetEntriesDao>(
      () => databaseModule.budgetEntriesDao(gh<_i979.AppDatabase>()),
    );
    gh.lazySingleton<_i268.TransactionsDao>(
      () => databaseModule.transactionsDao(gh<_i979.AppDatabase>()),
    );
    gh.lazySingleton<_i112.IBudgetRepository>(
      () => _i927.BudgetRepository(
        gh<_i861.BudgetEntriesDao>(),
        gh<_i268.TransactionsDao>(),
      ),
    );
    gh.lazySingleton<_i112.ICategoryGroupsRepository>(
      () => _i385.CategoryGroupsRepository(gh<_i1034.CategoryGroupsDao>()),
    );
    gh.lazySingleton<_i112.ICategoriesRepository>(
      () => _i106.CategoriesRepository(gh<_i261.CategoriesDao>()),
    );
    gh.lazySingleton<_i112.ITransactionsRepository>(
      () => _i228.TransactionsRepository(
        gh<_i268.TransactionsDao>(),
        gh<_i112.IBudgetRepository>(),
      ),
    );
    gh.lazySingleton<_i112.IAccountsRepository>(
      () => _i65.AccountsRepository(gh<_i171.AccountsDao>()),
    );
    gh.factory<_i485.BudgetBloc>(
      () => _i485.BudgetBloc(
        gh<_i112.IBudgetRepository>(),
        gh<_i112.ICategoryGroupsRepository>(),
        gh<_i112.ICategoriesRepository>(),
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i1017.SeedService>(
      () => _i1017.SeedService(
        gh<_i460.SharedPreferences>(),
        gh<_i112.IAccountsRepository>(),
        gh<_i112.ICategoryGroupsRepository>(),
        gh<_i112.ICategoriesRepository>(),
      ),
    );
    return this;
  }
}

class _$AppModule extends _i301.AppModule {}

class _$DatabaseModule extends _i342.DatabaseModule {}
