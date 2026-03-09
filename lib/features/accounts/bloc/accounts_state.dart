part of 'accounts_bloc.dart';

sealed class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];
}

final class AccountsInitial extends AccountsState {
  const AccountsInitial();
}

final class AccountsLoading extends AccountsState {
  const AccountsLoading();
}

final class AccountsLoaded extends AccountsState {
  const AccountsLoaded({required this.accounts});

  final List<Account> accounts;

  /// On-budget accounts (checking, savings, cash, credit cards tracked in
  /// the budget).
  List<Account> get budgetAccounts =>
      accounts.where((a) => a.onBudget).toList();

  /// Off-budget / tracking accounts.
  List<Account> get trackingAccounts =>
      accounts.where((a) => !a.onBudget).toList();

  /// Net worth in minor currency units — sum of all on-budget account
  /// balances. Credit card balances are negative (liabilities).
  int get netWorth =>
      accounts.where((a) => a.onBudget).fold(0, (s, a) => s + a.balance);

  @override
  List<Object?> get props => [accounts];
}

final class AccountsError extends AccountsState {
  const AccountsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
