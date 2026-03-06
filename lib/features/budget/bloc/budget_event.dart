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
