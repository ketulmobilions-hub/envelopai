import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

@injectable
class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  AccountsBloc(this._accountsRepository) : super(const AccountsInitial()) {
    on<AccountsStarted>(_onStarted, transformer: restartable());
    on<AccountAdded>(_onAccountAdded, transformer: sequential());
  }

  final IAccountsRepository _accountsRepository;

  Future<void> _onStarted(
    AccountsStarted event,
    Emitter<AccountsState> emit,
  ) async {
    emit(const AccountsLoading());
    await emit.forEach(
      _accountsRepository.watchAll(),
      onData: (accounts) => AccountsLoaded(accounts: accounts),
      onError: (error, _) => AccountsError(message: error.toString()),
    );
  }

  Future<void> _onAccountAdded(
    AccountAdded event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await _accountsRepository.addAccount(event.account);
      // The watchAll() stream re-emits automatically.
    } on Object catch (e) {
      emit(AccountsError(message: e.toString()));
    }
  }
}
