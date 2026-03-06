import 'package:equatable/equatable.dart';

class BudgetEntry extends Equatable {
  const BudgetEntry({
    required this.id,
    required this.categoryId,
    required this.month,
    required this.year,
    required this.budgeted,
    required this.activity,
    required this.available,
  }) : assert(month >= 1 && month <= 12, 'month must be between 1 and 12'),
       assert(year >= 1900, 'year must be >= 1900');

  final String id;
  final String categoryId;

  /// 1–12
  final int month;
  final int year;

  /// Amount manually assigned to this category for the month, in minor
  /// currency units (e.g. cents).
  final int budgeted;

  /// Sum of transactions in this category for the month, in minor currency
  /// units (auto-calculated).
  final int activity;

  /// budgeted + previous-month rollover − activity, in minor currency units.
  final int available;

  BudgetEntry copyWith({
    String? id,
    String? categoryId,
    int? month,
    int? year,
    int? budgeted,
    int? activity,
    int? available,
  }) {
    return BudgetEntry(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      month: month ?? this.month,
      year: year ?? this.year,
      budgeted: budgeted ?? this.budgeted,
      activity: activity ?? this.activity,
      available: available ?? this.available,
    );
  }

  @override
  List<Object?> get props => [
    id,
    categoryId,
    month,
    year,
    budgeted,
    activity,
    available,
  ];
}
