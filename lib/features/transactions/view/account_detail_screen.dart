import 'package:envelope/app/router/app_router.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/transactions/bloc/transaction_list_bloc.dart';
import 'package:envelope/features/transactions/widgets/transaction_row.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionListBloc>()
        ..add(TransactionListStarted(accountId: accountId)),
      child: _AccountDetailView(accountId: accountId),
    );
  }
}

// ---------------------------------------------------------------------------
// View
// ---------------------------------------------------------------------------

class _AccountDetailView extends StatelessWidget {
  const _AccountDetailView({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TransactionListBloc, TransactionListState>(
      builder: (context, state) {
        return switch (state) {
          TransactionListInitial() ||
          TransactionListLoading() =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
          TransactionListError(:final message) => Scaffold(
              appBar: AppBar(),
              body: Center(
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
            ),
          TransactionListLoaded() => _AccountDetailLoaded(state: state),
        };
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loaded state — full screen content
// ---------------------------------------------------------------------------

class _AccountDetailLoaded extends StatefulWidget {
  const _AccountDetailLoaded({required this.state});

  final TransactionListLoaded state;

  @override
  State<_AccountDetailLoaded> createState() => _AccountDetailLoadedState();
}

class _AccountDetailLoadedState extends State<_AccountDetailLoaded> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddTransaction(BuildContext context) async {
    await context.pushNamed(
      AppRoutes.addTransaction,
      queryParameters: {'accountId': widget.state.account.id},
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final account = state.account;

    return Scaffold(
      appBar: AppBar(
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.balance),
            tooltip: 'Reconcile',
            onPressed: () => context.pushNamed(
              AppRoutes.reconcile,
              pathParameters: {AppRouteParams.id: account.id},
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddTransaction(context),
        tooltip: 'Add transaction',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _AccountHeader(account: account),
          const Divider(height: 1),
          _SearchBar(controller: _searchController),
          _FilterChips(activeFilter: state.filter),
          const Divider(height: 1),
          Expanded(
            child: _TransactionList(state: state),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account header — cleared / uncleared balances
// ---------------------------------------------------------------------------

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final uncleared = account.balance - account.clearedBalance;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _BalanceColumn(
            label: 'Cleared',
            amount: account.clearedBalance,
            labelStyle: labelStyle,
            theme: theme,
          ),
          _BalanceColumn(
            label: 'Uncleared',
            amount: uncleared,
            labelStyle: labelStyle,
            theme: theme,
          ),
          _BalanceColumn(
            label: 'Total',
            amount: account.balance,
            labelStyle: labelStyle,
            theme: theme,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _BalanceColumn extends StatelessWidget {
  const _BalanceColumn({
    required this.label,
    required this.amount,
    required this.labelStyle,
    required this.theme,
    this.bold = false,
  });

  static final _fmt = NumberFormat.currency(symbol: r'$');

  final String label;
  final int amount;
  final TextStyle? labelStyle;
  final ThemeData theme;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 2),
        Text(
          _fmt.format(amount / 100),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: amount < 0 ? theme.colorScheme.error : null,
            fontWeight: bold ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.controller});

  final TextEditingController controller;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Search payee or memo…',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    context
                        .read<TransactionListBloc>()
                        .add(const TransactionListSearchChanged(query: ''));
                  },
                )
              : null,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        onChanged: (value) {
          context
              .read<TransactionListBloc>()
              .add(TransactionListSearchChanged(query: value));
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chips
// ---------------------------------------------------------------------------

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.activeFilter});

  final TransactionFilter activeFilter;

  static String _label(TransactionFilter filter) => switch (filter) {
        TransactionFilter.all => 'All',
        TransactionFilter.cleared => 'Cleared',
        TransactionFilter.uncleared => 'Uncleared',
        TransactionFilter.thisMonth => 'This Month',
        TransactionFilter.lastMonth => 'Last Month',
      };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: TransactionFilter.values.map((filter) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_label(filter)),
              selected: activeFilter == filter,
              onSelected: (_) => context
                  .read<TransactionListBloc>()
                  .add(TransactionListFilterChanged(filter: filter)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Transaction list — grouped by date
// ---------------------------------------------------------------------------

class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.state});

  final TransactionListLoaded state;

  static final _dateHeaderFmt = DateFormat('EEEE, MMM d, y');

  /// Interleaves [DateTime] date-header items with [Transaction] items,
  /// sorted descending by date.
  static List<Object> _buildItems(List<Transaction> transactions) {
    if (transactions.isEmpty) return [];

    // Sort descending (most recent first)
    final sorted = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    final items = <Object>[];
    DateTime? lastDate;

    for (final tx in sorted) {
      // Use UTC midnight so grouping is consistent with stored UTC dates.
      final txDate =
          DateTime.utc(tx.date.year, tx.date.month, tx.date.day);
      if (lastDate == null || txDate != lastDate) {
        items.add(txDate);
        lastDate = txDate;
      }
      items.add(tx);
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final transactions = state.filtered;

    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            state.transactions.isEmpty
                ? 'No transactions yet.\nTap + to add one.'
                : 'No transactions match your search or filter.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final items = _buildItems(transactions);

    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is DateTime) {
          return _DateHeader(date: item, formatter: _dateHeaderFmt);
        }
        final tx = item as Transaction;
        return _SwipeableTransactionRow(
          key: ValueKey(tx.id),
          transaction: tx,
          categoryNames: state.categoryNames,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Date separator header
// ---------------------------------------------------------------------------

class _DateHeader extends StatelessWidget {
  const _DateHeader({required this.date, required this.formatter});

  final DateTime date;
  final DateFormat formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        formatter.format(date),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Swipeable transaction row
// ---------------------------------------------------------------------------

class _SwipeableTransactionRow extends StatelessWidget {
  const _SwipeableTransactionRow({
    required this.transaction,
    required this.categoryNames,
    super.key,
  });

  final Transaction transaction;
  final Map<String, String> categoryNames;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(transaction.id),
      // Right swipe background: toggle cleared
      background: Container(
        color: theme.colorScheme.primaryContainer,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: Icon(
          transaction.cleared ? Icons.remove_done : Icons.check,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
      // Left swipe background: delete
      secondaryBackground: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Toggle cleared — don't remove from list
          context
              .read<TransactionListBloc>()
              .add(TransactionListClearedToggled(transaction: transaction));
          return false;
        }
        // Delete direction — confirm via dismiss
        return true;
      },
      onDismissed: (direction) {
        // Only fires for endToStart (delete)
        final bloc = context.read<TransactionListBloc>();
        bloc.add(
          TransactionListTransactionDeleted(transaction: transaction),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted "${transaction.payee}"'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                bloc.add(
                  TransactionListUndoDelete(transaction: transaction),
                );
              },
            ),
          ),
        );
      },
      child: InkWell(
        onTap: () => context.pushNamed(
          AppRoutes.editTransaction,
          pathParameters: {AppRouteParams.id: transaction.id},
        ),
        child: TransactionRow(
          transaction: transaction,
          categoryNames: categoryNames,
        ),
      ),
    );
  }
}
