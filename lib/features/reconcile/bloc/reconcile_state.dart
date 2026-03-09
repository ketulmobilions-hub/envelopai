part of 'reconcile_bloc.dart';

sealed class ReconcileState extends Equatable {
  const ReconcileState();
}

class ReconcileInitial extends ReconcileState {
  const ReconcileInitial();

  @override
  List<Object?> get props => [];
}

class ReconcileLoading extends ReconcileState {
  const ReconcileLoading();

  @override
  List<Object?> get props => [];
}

class ReconcileActive extends ReconcileState {
  const ReconcileActive({
    required this.account,
    required this.unclearedTransactions,
    required this.toggledIds,
    required this.statementBalance,
  });

  final Account account;

  /// All non-deleted, uncleared transactions for the account (from stream).
  final List<Transaction> unclearedTransactions;

  /// IDs of transactions locally marked cleared in this reconcile session.
  /// These are persisted only when [ReconcileConfirmed] is dispatched.
  final Set<String> toggledIds;

  /// Statement balance entered by the user, in minor currency units (cents).
  final int statementBalance;

  // ---------------------------------------------------------------------------
  // Derived values
  // ---------------------------------------------------------------------------

  /// Sum of amounts of all locally-toggled transactions.
  int get pendingAmount =>
      unclearedTransactions
          .where((t) => toggledIds.contains(t.id))
          .fold(0, (sum, t) => sum + t.amount);

  /// Cleared balance after applying all pending toggles.
  int get projectedClearedBalance => account.clearedBalance + pendingAmount;

  /// How much is left to clear.
  /// Positive: under-reconciled (cleared < statement — clear more).
  /// Negative: over-reconciled (cleared > statement — un-clear some).
  /// Zero: balanced — ready to reconcile.
  int get difference => statementBalance - projectedClearedBalance;

  bool get isBalanced => difference == 0;

  ReconcileActive copyWith({
    Account? account,
    List<Transaction>? unclearedTransactions,
    Set<String>? toggledIds,
    int? statementBalance,
  }) {
    return ReconcileActive(
      account: account ?? this.account,
      unclearedTransactions:
          unclearedTransactions ?? this.unclearedTransactions,
      toggledIds: toggledIds ?? this.toggledIds,
      statementBalance: statementBalance ?? this.statementBalance,
    );
  }

  @override
  List<Object?> get props =>
      [account, unclearedTransactions, toggledIds, statementBalance];
}

class ReconcileComplete extends ReconcileState {
  const ReconcileComplete();

  @override
  List<Object?> get props => [];
}

class ReconcileError extends ReconcileState {
  const ReconcileError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
