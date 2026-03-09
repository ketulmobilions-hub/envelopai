part of 'budget_bloc.dart';

sealed class BudgetEvent extends Equatable {
  const BudgetEvent();

  @override
  List<Object?> get props => [];
}

/// Emitted when the user navigates to a different month (or on initial load).
final class BudgetMonthChanged extends BudgetEvent {
  const BudgetMonthChanged({required this.month, required this.year});

  final int month;
  final int year;

  @override
  List<Object?> get props => [month, year];
}

/// Emitted when the user sets a new budgeted amount for a category.
///
/// [budgeted] is in minor currency units (cents). The bloc writes the value
/// to the repository; the reactive stream then updates TBB and available
/// automatically.
final class BudgetEntryAllocated extends BudgetEvent {
  const BudgetEntryAllocated({
    required this.categoryId,
    required this.month,
    required this.year,
    required this.budgeted,
  });

  final String categoryId;
  final int month;
  final int year;

  /// New budgeted amount in minor currency units.
  final int budgeted;

  @override
  List<Object?> get props => [categoryId, month, year, budgeted];
}

/// Emitted when the user moves budget from one category to another.
///
/// [amount] is in minor currency units (cents) and must be > 0. The bloc
/// writes both changes atomically; the reactive stream re-emits automatically.
final class BudgetMoneyMoved extends BudgetEvent {
  const BudgetMoneyMoved({
    required this.fromCategoryId,
    required this.toCategoryId,
    required this.month,
    required this.year,
    required this.amount,
  });

  final String fromCategoryId;
  final String toCategoryId;
  final int month;
  final int year;

  /// Amount to transfer in minor currency units.
  final int amount;

  @override
  List<Object?> get props =>
      [fromCategoryId, toCategoryId, month, year, amount];
}
