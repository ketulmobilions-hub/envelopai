part of 'budget_bloc.dart';

sealed class BudgetState extends Equatable {
  const BudgetState();

  @override
  List<Object?> get props => [];
}

final class BudgetInitial extends BudgetState {
  const BudgetInitial();
}

final class BudgetLoading extends BudgetState {
  const BudgetLoading();
}

final class BudgetLoaded extends BudgetState {
  const BudgetLoaded({
    required this.entries,
    required this.tbb,
    required this.groups,
    required this.categories,
    required this.month,
    required this.year,
  });

  final List<BudgetEntry> entries;

  /// To-Be-Budgeted: income this month minus total budgeted, in minor
  /// currency units. Positive = money available to assign; negative =
  /// over-budgeted.
  final int tbb;

  /// All category groups, sorted by `sortOrder`.
  final List<CategoryGroup> groups;

  /// All categories across all groups, sorted by `sortOrder` within group.
  final List<Category> categories;

  final int month;
  final int year;

  @override
  List<Object?> get props => [entries, tbb, groups, categories, month, year];
}

final class BudgetError extends BudgetState {
  const BudgetError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
