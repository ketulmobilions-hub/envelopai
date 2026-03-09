part of 'transaction_list_bloc.dart';

enum TransactionFilter { all, cleared, uncleared, thisMonth, lastMonth }

sealed class TransactionListState extends Equatable {
  const TransactionListState();
}

class TransactionListInitial extends TransactionListState {
  const TransactionListInitial();

  @override
  List<Object?> get props => [];
}

class TransactionListLoading extends TransactionListState {
  const TransactionListLoading();

  @override
  List<Object?> get props => [];
}

class TransactionListLoaded extends TransactionListState {
  const TransactionListLoaded({
    required this.account,
    required this.transactions,
    required this.categoryNames,
    this.query = '',
    this.filter = TransactionFilter.all,
  });

  final Account account;

  /// All non-deleted transactions for the account (from the stream).
  final List<Transaction> transactions;

  /// Maps categoryId → category name for display.
  final Map<String, String> categoryNames;

  final String query;
  final TransactionFilter filter;

  /// Transactions after applying [query] and [filter].
  List<Transaction> get filtered {
    var result = transactions;

    // Apply filter chip
    final now = DateTime.now();
    result = switch (filter) {
      TransactionFilter.all => result,
      TransactionFilter.cleared => result.where((t) => t.cleared).toList(),
      TransactionFilter.uncleared => result.where((t) => !t.cleared).toList(),
      TransactionFilter.thisMonth => result
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList(),
      TransactionFilter.lastMonth => () {
          final lastMonth = DateTime(now.year, now.month - 1);
          return result
              .where(
                (t) =>
                    t.date.year == lastMonth.year &&
                    t.date.month == lastMonth.month,
              )
              .toList();
        }(),
    };

    // Apply search query
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where(
            (t) =>
                t.payee.toLowerCase().contains(q) ||
                (t.memo?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }

    return result;
  }

  TransactionListLoaded copyWith({
    Account? account,
    List<Transaction>? transactions,
    Map<String, String>? categoryNames,
    String? query,
    TransactionFilter? filter,
  }) {
    return TransactionListLoaded(
      account: account ?? this.account,
      transactions: transactions ?? this.transactions,
      categoryNames: categoryNames ?? this.categoryNames,
      query: query ?? this.query,
      filter: filter ?? this.filter,
    );
  }

  @override
  List<Object?> get props =>
      [account, transactions, categoryNames, query, filter];
}

class TransactionListError extends TransactionListState {
  const TransactionListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
