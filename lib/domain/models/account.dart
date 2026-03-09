import 'package:equatable/equatable.dart';

enum AccountType { checking, savings, creditCard, cash }

class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.clearedBalance,
    required this.currency,
    required this.onBudget,
    this.lastReconciledAt,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Balance in minor currency units (e.g. cents). Positive = asset,
  /// negative = liability.
  final int balance;

  /// Cleared balance in minor currency units.
  final int clearedBalance;

  final String currency;
  final bool onBudget;

  /// UTC timestamp of the last successful reconciliation, or null if never
  /// reconciled.
  final DateTime? lastReconciledAt;

  /// Note: passing `null` for [lastReconciledAt] is a no-op (the existing
  /// value is kept). There is no mechanism to explicitly clear the field
  /// since that use case does not exist.
  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    int? balance,
    int? clearedBalance,
    String? currency,
    bool? onBudget,
    DateTime? lastReconciledAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      clearedBalance: clearedBalance ?? this.clearedBalance,
      currency: currency ?? this.currency,
      onBudget: onBudget ?? this.onBudget,
      lastReconciledAt: lastReconciledAt ?? this.lastReconciledAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    clearedBalance,
    currency,
    onBudget,
    lastReconciledAt,
  ];
}
