part of 'transaction_form_bloc.dart';

sealed class TransactionFormEvent extends Equatable {
  const TransactionFormEvent();
}

final class TransactionFormStarted extends TransactionFormEvent {
  const TransactionFormStarted({this.transactionId, this.initialAccountId});

  /// Non-null when editing an existing transaction.
  final String? transactionId;

  /// Pre-selects this account when adding a new transaction.
  final String? initialAccountId;

  @override
  List<Object?> get props => [transactionId, initialAccountId];
}

final class TransactionFormSubmitted extends TransactionFormEvent {
  const TransactionFormSubmitted({required this.transaction});

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

/// Dispatched when the user saves a transfer transaction.
final class TransactionFormTransferSubmitted extends TransactionFormEvent {
  const TransactionFormTransferSubmitted({
    required this.fromAccountId,
    required this.toAccountId,
    required this.fromAccountName,
    required this.toAccountName,
    required this.amount,
    required this.date,
    this.memo,
    this.cleared = false,
  });

  final String fromAccountId;
  final String toAccountId;

  /// Human-readable account names stored as payees on each transfer leg.
  final String fromAccountName;
  final String toAccountName;

  /// Positive amount in minor currency units (cents).
  final int amount;

  final DateTime date;
  final String? memo;
  final bool cleared;

  @override
  List<Object?> get props => [
    fromAccountId,
    toAccountId,
    fromAccountName,
    toAccountName,
    amount,
    date,
    memo,
    cleared,
  ];
}
