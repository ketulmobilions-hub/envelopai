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
