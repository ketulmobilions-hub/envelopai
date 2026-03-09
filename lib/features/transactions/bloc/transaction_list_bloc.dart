import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'transaction_list_event.dart';
part 'transaction_list_state.dart';

@injectable
class TransactionListBloc
    extends Bloc<TransactionListEvent, TransactionListState> {
  TransactionListBloc(
    this._txRepo,
    this._accountRepo,
    this._catRepo,
  ) : super(const TransactionListInitial()) {
    on<TransactionListStarted>(_onStarted, transformer: restartable());
    on<TransactionListSearchChanged>(_onSearchChanged);
    on<TransactionListFilterChanged>(_onFilterChanged);
    on<TransactionListTransactionDeleted>(
      _onDeleted,
      transformer: sequential(),
    );
    on<TransactionListUndoDelete>(_onUndoDelete, transformer: sequential());
    on<TransactionListClearedToggled>(
      _onClearedToggled,
      transformer: sequential(),
    );
  }

  final ITransactionsRepository _txRepo;
  final IAccountsRepository _accountRepo;
  final ICategoriesRepository _catRepo;

  Future<void> _onStarted(
    TransactionListStarted event,
    Emitter<TransactionListState> emit,
  ) async {
    emit(const TransactionListLoading());
    try {
      final account = await _accountRepo.getById(event.accountId);
      if (account == null) {
        emit(const TransactionListError('Account not found'));
        return;
      }
      final categories = await _catRepo.getAll();
      // TODO(Phase 3): subscribe to _catRepo.watchAll() for live names.
      final categoryNames = {for (final c in categories) c.id: c.name};

      await emit.forEach<List<Transaction>>(
        _txRepo.watchByAccount(event.accountId),
        onData: (transactions) {
          final current = state;
          final query =
              current is TransactionListLoaded ? current.query : '';
          final filter = current is TransactionListLoaded
              ? current.filter
              : TransactionFilter.all;
          return TransactionListLoaded(
            account: account,
            transactions: transactions,
            categoryNames: categoryNames,
            query: query,
            filter: filter,
          );
        },
        onError: (_, _) =>
            const TransactionListError('Failed to load transactions'),
      );
    } on Object catch (e) {
      emit(TransactionListError(e.toString()));
    }
  }

  void _onSearchChanged(
    TransactionListSearchChanged event,
    Emitter<TransactionListState> emit,
  ) {
    final current = state;
    if (current is! TransactionListLoaded) return;
    emit(current.copyWith(query: event.query));
  }

  void _onFilterChanged(
    TransactionListFilterChanged event,
    Emitter<TransactionListState> emit,
  ) {
    final current = state;
    if (current is! TransactionListLoaded) return;
    emit(current.copyWith(filter: event.filter));
  }

  Future<void> _onDeleted(
    TransactionListTransactionDeleted event,
    Emitter<TransactionListState> emit,
  ) async {
    try {
      await _txRepo.deleteTransaction(
        event.transaction.id,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    } on Object catch (e) {
      emit(TransactionListError(e.toString()));
    }
  }

  Future<void> _onUndoDelete(
    TransactionListUndoDelete event,
    Emitter<TransactionListState> emit,
  ) async {
    try {
      await _txRepo.updateTransaction(
        event.transaction.copyWith(
          isDeleted: false,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } on Object catch (e) {
      emit(TransactionListError(e.toString()));
    }
  }

  Future<void> _onClearedToggled(
    TransactionListClearedToggled event,
    Emitter<TransactionListState> emit,
  ) async {
    try {
      await _txRepo.updateTransaction(
        event.transaction.copyWith(
          cleared: !event.transaction.cleared,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } on Object catch (e) {
      emit(TransactionListError(e.toString()));
    }
  }
}
