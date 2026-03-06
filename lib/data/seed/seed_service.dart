import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identifies a default category group together with its child categories.
class _GroupDef {
  const _GroupDef(
    this.name,
    this.categories, {
    this.isHidden = false,
  });

  final String name;
  final bool isHidden;
  final List<String> categories;
}

const _defaultGroups = [
  _GroupDef('Fixed Bills', [
    'Rent/Mortgage',
    'Electricity',
    'Water',
    'Internet',
    'Insurance',
  ]),
  _GroupDef('Everyday Expenses', [
    'Groceries',
    'Dining Out',
    'Transport',
    'Fuel',
    'Personal Care',
  ]),
  _GroupDef('Savings Goals', [
    'Emergency Fund',
    'Vacation',
    'New Car',
  ]),
  _GroupDef('Debt Payments', [
    'Credit Card',
    'Student Loan',
  ]),
  _GroupDef('Income', ['Salary', 'Freelance', 'Other Income'], isHidden: true),
];

/// Persists default accounts, category groups, and categories on the very
/// first launch of the app.  Subsequent calls are no-ops (guarded by a
/// [SharedPreferences] flag).
@LazySingleton()
class SeedService {
  SeedService(
    this._prefs,
    this._accounts,
    this._categoryGroups,
    this._categories,
  );

  static const _seedKey = 'data_seeded_v1';
  static const _uuid = Uuid();

  final SharedPreferences _prefs;
  final IAccountsRepository _accounts;
  final ICategoryGroupsRepository _categoryGroups;
  final ICategoriesRepository _categories;

  /// Seeds default data if it has not been done before.
  /// Safe to call on every app launch — the operation runs at most once.
  Future<void> seedIfNeeded() async {
    if (_prefs.getBool(_seedKey) ?? false) return;
    await _seed();
    await _prefs.setBool(_seedKey, true);
  }

  Future<void> _seed() async {
    await _accounts.addAccount(
      Account(
        id: _uuid.v4(),
        name: 'My Checking Account',
        type: AccountType.checking,
        balance: 0,
        clearedBalance: 0,
        currency: 'USD',
        onBudget: true,
      ),
    );

    for (var i = 0; i < _defaultGroups.length; i++) {
      final def = _defaultGroups[i];
      final groupId = _uuid.v4();

      await _categoryGroups.save(
        CategoryGroup(
          id: groupId,
          name: def.name,
          sortOrder: i,
          isHidden: def.isHidden,
        ),
      );

      for (var j = 0; j < def.categories.length; j++) {
        await _categories.save(
          Category(
            id: _uuid.v4(),
            groupId: groupId,
            name: def.categories[j],
            sortOrder: j,
          ),
        );
      }
    }
  }
}
