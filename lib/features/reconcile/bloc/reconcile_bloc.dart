import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'reconcile_event.dart';
part 'reconcile_state.dart';

@injectable
class ReconcileBloc extends Bloc<ReconcileEvent, ReconcileState> {
  ReconcileBloc(this._txRepo, this._accountRepo)
    : super(const ReconcileInitial()) {
    on<ReconcileStarted>(_onStarted, transformer: restartable());
    on<ReconcileStatementBalanceChanged>(_onStatementBalanceChanged);
    on<ReconcileTransactionToggled>(_onTransactionToggled);
    on<ReconcileConfirmed>(_onConfirmed, transformer: sequential());
  }

  final ITransactionsRepository _txRepo;
  final IAccountsRepository _accountRepo;

  Future<void> _onStarted(
    ReconcileStarted event,
    Emitter<ReconcileState> emit,
  ) async {
    emit(const ReconcileLoading());
    try {
      final account = await _accountRepo.getById(event.accountId);
      if (account == null) {
        emit(const ReconcileError('Account not found'));
        return;
      }

      await emit.forEach<List<Transaction>>(
        _txRepo.watchUnclearedByAccount(event.accountId),
        onData: (txs) {
          final current = state;
          final toggledIds =
              current is ReconcileActive ? current.toggledIds : <String>{};
          final statementBalance =
              current is ReconcileActive ? current.statementBalance : 0;
          // Keep only ids that still exist in the stream (e.g. after confirm
          // the list shrinks — clear stale toggled ids automatically).
          final validIds = txs.map((t) => t.id).toSet();
          return ReconcileActive(
            account: account,
            unclearedTransactions: txs,
            toggledIds: toggledIds.intersection(validIds),
            statementBalance: statementBalance,
          );
        },
        onError: (_, _) =>
            const ReconcileError('Failed to load transactions'),
      );
    } on Object catch (e) {
      emit(ReconcileError(e.toString()));
    }
  }

  void _onStatementBalanceChanged(
    ReconcileStatementBalanceChanged event,
    Emitter<ReconcileState> emit,
  ) {
    final current = state;
    if (current is! ReconcileActive) return;
    emit(current.copyWith(statementBalance: event.amountCents));
  }

  void _onTransactionToggled(
    ReconcileTransactionToggled event,
    Emitter<ReconcileState> emit,
  ) {
    final current = state;
    if (current is! ReconcileActive) return;
    final id = event.transaction.id;
    final updated = Set<String>.from(current.toggledIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    emit(current.copyWith(toggledIds: updated));
  }

  Future<void> _onConfirmed(
    ReconcileConfirmed event,
    Emitter<ReconcileState> emit,
  ) async {
    final current = state;
    if (current is! ReconcileActive) return;

    final toMarkCleared = current.unclearedTransactions
        .where((t) => current.toggledIds.contains(t.id))
        .toList();

    try {
      await _txRepo.reconcileAccount(
        account: current.account,
        transactionsToMarkCleared: toMarkCleared,
        adjustmentAmountCents:
            event.createAdjustment ? current.difference : null,
      );
      emit(const ReconcileComplete());
    } on Object catch (e) {
      emit(ReconcileError(e.toString()));
    }
  }
}
