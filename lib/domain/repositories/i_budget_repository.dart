import 'package:envelope/domain/models/models.dart';

abstract interface class IBudgetRepository {
  Stream<List<BudgetEntry>> watchAll();
  Future<List<BudgetEntry>> getAll();
  Future<BudgetEntry?> getById(String id);
  Stream<List<BudgetEntry>> watchForMonth(int month, int year);
  Future<BudgetEntry> getOrCreate(String categoryId, int month, int year);
  Future<void> save(BudgetEntry entry);
  Future<void> updateAvailable(String id, int available);
  Future<void> deleteById(String id);

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
}
