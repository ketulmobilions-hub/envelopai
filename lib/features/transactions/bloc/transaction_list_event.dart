part of 'transaction_list_bloc.dart';

sealed class TransactionListEvent extends Equatable {
  const TransactionListEvent();
}

class TransactionListStarted extends TransactionListEvent {
  const TransactionListStarted({required this.accountId});

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

class TransactionListSearchChanged extends TransactionListEvent {
  const TransactionListSearchChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

class TransactionListFilterChanged extends TransactionListEvent {
  const TransactionListFilterChanged({required this.filter});

  final TransactionFilter filter;

  @override
  List<Object?> get props => [filter];
}

class TransactionListTransactionDeleted extends TransactionListEvent {
  const TransactionListTransactionDeleted({required this.transaction});

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class TransactionListUndoDelete extends TransactionListEvent {
  const TransactionListUndoDelete({required this.transaction});

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class TransactionListClearedToggled extends TransactionListEvent {
  const TransactionListClearedToggled({required this.transaction});

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}
