part of 'transaction_form_bloc.dart';

sealed class TransactionFormState extends Equatable {
  const TransactionFormState();
}

final class TransactionFormInitial extends TransactionFormState {
  const TransactionFormInitial();

  @override
  List<Object?> get props => [];
}

final class TransactionFormLoading extends TransactionFormState {
  const TransactionFormLoading();

  @override
  List<Object?> get props => [];
}

/// Data is loaded and the form is ready for input.
///
/// [isSubmitting] is true while a save is in flight — the save button should
/// be disabled and a progress indicator shown.
/// [saveError] is set to the error message if the most recent save attempt
/// failed; the UI should display a snack-bar and clear the error on the next
/// attempt.
final class TransactionFormReady extends TransactionFormState {
  const TransactionFormReady({
    required this.accounts,
    required this.groups,
    required this.categories,
    this.existing,
    this.isSubmitting = false,
    this.saveError,
  });

  final List<Account> accounts;
  final List<CategoryGroup> groups;
  final List<Category> categories;

  /// Non-null when editing an existing transaction.
  final Transaction? existing;

  final bool isSubmitting;

  /// Non-null when the previous save attempt failed.
  final String? saveError;

  @override
  List<Object?> get props => [
    accounts,
    groups,
    categories,
    existing,
    isSubmitting,
    saveError,
  ];
}

/// Emitted once after a successful save; the screen should pop on this state.
final class TransactionFormSaved extends TransactionFormState {
  const TransactionFormSaved();

  @override
  List<Object?> get props => [];
}

/// Emitted when the initial data load fails.
final class TransactionFormError extends TransactionFormState {
  const TransactionFormError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
