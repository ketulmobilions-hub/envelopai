part of 'reconcile_bloc.dart';

sealed class ReconcileEvent extends Equatable {
  const ReconcileEvent();
}

class ReconcileStarted extends ReconcileEvent {
  const ReconcileStarted({required this.accountId});

  final String accountId;

  @override
  List<Object?> get props => [accountId];
}

class ReconcileStatementBalanceChanged extends ReconcileEvent {
  const ReconcileStatementBalanceChanged({required this.amountCents});

  /// Statement balance in minor currency units (cents).
  final int amountCents;

  @override
  List<Object?> get props => [amountCents];
}

class ReconcileTransactionToggled extends ReconcileEvent {
  const ReconcileTransactionToggled({required this.transaction});

  final Transaction transaction;

  @override
  List<Object?> get props => [transaction];
}

class ReconcileConfirmed extends ReconcileEvent {
  const ReconcileConfirmed({this.createAdjustment = false});

  /// When true, an adjustment transaction is created to cover any remaining
  /// difference between the projected cleared balance and the statement
  /// balance.
  final bool createAdjustment;

  @override
  List<Object?> get props => [createAdjustment];
}
