import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'transaction_form_event.dart';
part 'transaction_form_state.dart';

@injectable
class TransactionFormBloc
    extends Bloc<TransactionFormEvent, TransactionFormState> {
  TransactionFormBloc(
    this._accountsRepo,
    this._categoryGroupsRepo,
    this._categoriesRepo,
    this._transactionsRepo,
  ) : super(const TransactionFormInitial()) {
    on<TransactionFormStarted>(_onStarted, transformer: restartable());
    on<TransactionFormSubmitted>(_onSubmitted, transformer: sequential());
    on<TransactionFormTransferSubmitted>(
      _onTransferSubmitted,
      transformer: sequential(),
    );
  }

  final IAccountsRepository _accountsRepo;
  final ICategoryGroupsRepository _categoryGroupsRepo;
  final ICategoriesRepository _categoriesRepo;
  final ITransactionsRepository _transactionsRepo;

  Future<void> _onStarted(
    TransactionFormStarted event,
    Emitter<TransactionFormState> emit,
  ) async {
    emit(const TransactionFormLoading());
    try {
      // Fetch all three collections concurrently.
      final results = await Future.wait([
        _accountsRepo.getAll(),
        _categoryGroupsRepo.getAll(),
        _categoriesRepo.getAll(),
      ]);
      final accounts = results[0] as List<Account>;
      final groups = results[1] as List<CategoryGroup>;
      final categories = results[2] as List<Category>;

      Transaction? existing;
      if (event.transactionId != null) {
        existing = await _transactionsRepo.getById(event.transactionId!);
      }

      emit(
        TransactionFormReady(
          accounts: accounts,
          groups: groups,
          categories: categories,
          existing: existing,
        ),
      );
    } on Object catch (e) {
      emit(TransactionFormError(message: e.toString()));
    }
  }

  Future<void> _onSubmitted(
    TransactionFormSubmitted event,
    Emitter<TransactionFormState> emit,
  ) async {
    final current = state;
    if (current is! TransactionFormReady) return;

    // Mark as submitting so the UI can disable the save button.
    emit(
      TransactionFormReady(
        accounts: current.accounts,
        groups: current.groups,
        categories: current.categories,
        existing: current.existing,
        isSubmitting: true,
      ),
    );

    try {
      if (current.existing != null) {
        await _transactionsRepo.updateTransaction(event.transaction);
      } else {
        await _transactionsRepo.addTransaction(event.transaction);
      }
      emit(const TransactionFormSaved());
    } on Object catch (e) {
      // Return to the ready state so the form remains visible.
      emit(
        TransactionFormReady(
          accounts: current.accounts,
          groups: current.groups,
          categories: current.categories,
          existing: current.existing,
          saveError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onTransferSubmitted(
    TransactionFormTransferSubmitted event,
    Emitter<TransactionFormState> emit,
  ) async {
    final current = state;
    if (current is! TransactionFormReady) return;

    emit(
      TransactionFormReady(
        accounts: current.accounts,
        groups: current.groups,
        categories: current.categories,
        existing: current.existing,
        isSubmitting: true,
      ),
    );

    try {
      await _transactionsRepo.addTransfer(
        fromAccountId: event.fromAccountId,
        toAccountId: event.toAccountId,
        fromAccountName: event.fromAccountName,
        toAccountName: event.toAccountName,
        amount: event.amount,
        date: event.date,
        memo: event.memo,
        cleared: event.cleared,
      );
      emit(const TransactionFormSaved());
    } on Object catch (e) {
      emit(
        TransactionFormReady(
          accounts: current.accounts,
          groups: current.groups,
          categories: current.categories,
          existing: current.existing,
          saveError: e.toString(),
        ),
      );
    }
  }
}
