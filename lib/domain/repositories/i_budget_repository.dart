import 'package:envelope/domain/models/models.dart';

abstract interface class IBudgetRepository {
  Stream<List<BudgetEntry>> watchAll();
  Future<List<BudgetEntry>> getAll();
  Future<BudgetEntry?> getById(String id);
  Stream<List<BudgetEntry>> watchForMonth(int month, int year);

  /// Combined stream of budget entries and the To-Be-Budgeted scalar.
  ///
  /// Re-emits whenever either entries or income transactions change, making
  /// both the category list and the TBB banner update in real time.
  Stream<({List<BudgetEntry> entries, int tbb})> watchMonthSummary(
    int month,
    int year,
  );

  Future<BudgetEntry> getOrCreate(String categoryId, int month, int year);
  Future<void> save(BudgetEntry entry);
  Future<void> updateAvailable(String id, int available);
  Future<void> deleteById(String id);

  /// Sets [budgeted] for the given category/month/year, creating the entry if
  /// it does not exist yet, then recalculates
  /// `available = budgeted − activity`.
  ///
  /// Because [watchMonthSummary] is reactive, both the category row and the
  /// TBB banner update automatically after this call.
  Future<void> allocate(
    String categoryId,
    int month,
    int year,
    int budgeted,
  );

  /// Atomically transfers [amount] of budget from [fromCategoryId] to
  /// [toCategoryId] for [month]/[year], updating `available` for both.
  Future<void> moveMoney(
    String fromCategoryId,
    String toCategoryId,
    int month,
    int year,
    int amount,
  );

  /// Recomputes `activity` (sum of transaction amounts, sign-flipped so
  /// expenses are positive) and `available` (budgeted − activity) for the
  /// given category / month / year, then persists both fields.
  ///
  /// Call this after every transaction mutation that affects a budget category.
  Future<void> recalculateAvailable(
    String categoryId,
    int month,
    int year,
  );

  /// Applies negative-available rollover from [month]/[year] to the next month.
  ///
  /// For each category overspent in [month]/[year], subtracts the shortfall
  /// from `budgeted` in the following month (which may result in a negative
  /// `budgeted` — see `BudgetEntriesDao.rolloverMonth` for details). Should be
  /// called at most once per month transition. The idempotency guard is
  /// implemented in `BudgetBloc._applyRolloverIfNeeded` via
  /// `SharedPreferences`.
  Future<void> rolloverMonth(int month, int year);
}
