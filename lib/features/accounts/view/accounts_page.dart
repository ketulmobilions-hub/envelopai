import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/accounts/accounts.dart';
import 'package:envelope/features/accounts/widgets/add_account_sheet.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AccountsBloc>()..add(const AccountsStarted()),
      child: const _AccountsView(),
    );
  }
}

class _AccountsView extends StatelessWidget {
  const _AccountsView();

  static Future<void> _openAddSheet(BuildContext context) async {
    final account = await showModalBottomSheet<Account>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const AddAccountSheet(),
    );
    if (account == null || !context.mounted) return;
    context.read<AccountsBloc>().add(AccountAdded(account: account));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        tooltip: 'Add account',
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<AccountsBloc, AccountsState>(
        builder: (context, state) => switch (state) {
          AccountsInitial() || AccountsLoading() =>
            const Center(child: CircularProgressIndicator()),
          AccountsError(:final message) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          AccountsLoaded() => _AccountsLoaded(state: state),
        },
      ),
    );
  }
}

class _AccountsLoaded extends StatelessWidget {
  const _AccountsLoaded({required this.state});

  final AccountsLoaded state;

  @override
  Widget build(BuildContext context) {
    final budgetAccounts = state.budgetAccounts;
    final trackingAccounts = state.trackingAccounts;

    return ListView(
      children: [
        NetWorthCard(netWorth: state.netWorth),
        if (budgetAccounts.isNotEmpty) ...[
          const AccountColumnHeader(title: 'Budget Accounts'),
          const Divider(height: 1),
          ...budgetAccounts.map((a) => AccountRow(account: a)),
        ],
        if (trackingAccounts.isNotEmpty) ...[
          const AccountColumnHeader(title: 'Tracking Accounts'),
          const Divider(height: 1),
          ...trackingAccounts.map((a) => AccountRow(account: a)),
        ],
        if (state.accounts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No accounts yet.\nTap + to add your first account.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 80), // FAB clearance
      ],
    );
  }
}
