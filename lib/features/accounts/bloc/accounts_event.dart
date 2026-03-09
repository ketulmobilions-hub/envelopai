part of 'accounts_bloc.dart';

sealed class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers the initial watchAll() subscription.
final class AccountsStarted extends AccountsEvent {
  const AccountsStarted();
}

/// Emitted when the user saves a new account from the add-account sheet.
final class AccountAdded extends AccountsEvent {
  const AccountAdded({required this.account});

  final Account account;

  @override
  List<Object?> get props => [account];
}
