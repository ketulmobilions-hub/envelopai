import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/reconcile/bloc/reconcile_bloc.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Shared currency formatter for the entire reconcile screen.
final _currencyFmt = NumberFormat.currency(symbol: r'$');

class ReconcileScreen extends StatelessWidget {
  const ReconcileScreen({required this.accountId, super.key});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<ReconcileBloc>()..add(ReconcileStarted(accountId: accountId)),
      child: const _ReconcileView(),
    );
  }
}

// ---------------------------------------------------------------------------
// View — switches on state
// ---------------------------------------------------------------------------

class _ReconcileView extends StatelessWidget {
  const _ReconcileView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReconcileBloc, ReconcileState>(
      listener: (context, state) {
        if (state is ReconcileComplete) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account reconciled!')),
          );
          context.pop();
        }
      },
      builder: (context, state) {
        return switch (state) {
          ReconcileInitial() ||
          ReconcileLoading() =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
          ReconcileError(:final message) => Scaffold(
              appBar: AppBar(title: const Text('Reconcile')),
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
          ReconcileActive() => _ReconcileActiveScreen(state: state),
          ReconcileComplete() =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
        };
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Active reconcile screen
// ---------------------------------------------------------------------------

class _ReconcileActiveScreen extends StatefulWidget {
  const _ReconcileActiveScreen({required this.state});

  final ReconcileActive state;

  @override
  State<_ReconcileActiveScreen> createState() => _ReconcileActiveScreenState();
}

class _ReconcileActiveScreenState extends State<_ReconcileActiveScreen> {
  late final TextEditingController _balanceController;

  @override
  void initState() {
    super.initState();
    final initial = widget.state.statementBalance;
    _balanceController = TextEditingController(
      text: initial == 0 ? '' : (initial / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _balanceController.dispose();
    super.dispose();
  }

  void _onBalanceChanged(String raw) {
    final cents = _parseCents(raw);
    context
        .read<ReconcileBloc>()
        .add(ReconcileStatementBalanceChanged(amountCents: cents));
  }

  static int _parseCents(String raw) {
    if (raw.isEmpty) return 0;
    // Preserve the leading minus sign for credit-card balances.
    final isNegative = raw.startsWith('-');
    final cleaned = raw.replaceAll(RegExp(r'[^\d.]'), '');
    final value = double.tryParse(cleaned) ?? 0.0;
    final cents = (value * 100).round();
    return isNegative ? -cents : cents;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;

    return Scaffold(
      appBar: AppBar(title: Text('Reconcile ${state.account.name}')),
      body: Column(
        children: [
          _StatementBalanceInput(
            controller: _balanceController,
            onChanged: _onBalanceChanged,
          ),
          _BalanceSummary(state: state),
          const Divider(height: 1),
          Expanded(child: _UnclearedList(state: state)),
        ],
      ),
      bottomNavigationBar: _BottomBar(state: state),
    );
  }
}

// ---------------------------------------------------------------------------
// Statement balance input
// ---------------------------------------------------------------------------

class _StatementBalanceInput extends StatelessWidget {
  const _StatementBalanceInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-\d.]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Statement balance',
          prefixText: r'$ ',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Balance summary row
// ---------------------------------------------------------------------------

class _BalanceSummary extends StatelessWidget {
  const _BalanceSummary({required this.state});

  final ReconcileActive state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = state.difference;
    final diffColor = diff == 0
        ? theme.colorScheme.primary
        : theme.colorScheme.error;
    final diffLabel = diff == 0
        ? 'Balanced!'
        : diff > 0
            ? '${_currencyFmt.format(diff / 100)} remaining'
            : '${_currencyFmt.format(diff.abs() / 100)} over';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _SummaryItem(
            label: 'Cleared balance',
            value: _currencyFmt.format(state.projectedClearedBalance / 100),
            theme: theme,
          ),
          _SummaryItem(
            label: 'Statement',
            value: _currencyFmt.format(state.statementBalance / 100),
            theme: theme,
          ),
          _SummaryItem(
            label: 'Difference',
            value: diffLabel,
            valueColor: diffColor,
            theme: theme,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.theme,
    this.valueColor,
    this.bold = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: bold ? FontWeight.w600 : null,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Uncleared transaction list
// ---------------------------------------------------------------------------

class _UnclearedList extends StatelessWidget {
  const _UnclearedList({required this.state});

  final ReconcileActive state;

  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final txs = state.unclearedTransactions;

    if (txs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No uncleared transactions.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (context, index) {
        final tx = txs[index];
        final isToggled = state.toggledIds.contains(tx.id);
        return _UnclearedTransactionTile(
          transaction: tx,
          isToggled: isToggled,
          dateFmt: _dateFmt,
        );
      },
    );
  }
}

class _UnclearedTransactionTile extends StatelessWidget {
  const _UnclearedTransactionTile({
    required this.transaction,
    required this.isToggled,
    required this.dateFmt,
  });

  final Transaction transaction;
  final bool isToggled;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amount = transaction.amount;
    final amountColor = amount < 0 ? theme.colorScheme.error : null;

    return ListTile(
      leading: GestureDetector(
        onTap: () => context
            .read<ReconcileBloc>()
            .add(ReconcileTransactionToggled(transaction: transaction)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToggled
                ? theme.colorScheme.primary
                : Colors.transparent,
            border: Border.all(
              color: isToggled
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 2,
            ),
          ),
          child: isToggled
              ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
              : null,
        ),
      ),
      title: Text(
        transaction.payee,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isToggled ? theme.colorScheme.onSurfaceVariant : null,
          decoration: isToggled ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        dateFmt.format(transaction.date),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Text(
        _currencyFmt.format(amount / 100),
        style: theme.textTheme.bodyMedium?.copyWith(color: amountColor),
      ),
      onTap: () => context
          .read<ReconcileBloc>()
          .add(ReconcileTransactionToggled(transaction: transaction)),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom action bar
// ---------------------------------------------------------------------------

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final ReconcileActive state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diff = state.difference;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.isBalanced)
              FilledButton.icon(
                onPressed: () => context
                    .read<ReconcileBloc>()
                    .add(const ReconcileConfirmed()),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Reconcile Now'),
              )
            else ...[
              OutlinedButton(
                onPressed: null,
                child: Text(
                  'Reconcile Now',
                  style: TextStyle(color: theme.disabledColor),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonal(
                onPressed: () => _confirmAdjustment(context, diff),
                child: Text(
                  'Create Adjustment (${_fmtDiff(diff)})',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmtDiff(int diff) =>
      _currencyFmt.format(diff.abs() / 100);

  Future<void> _confirmAdjustment(BuildContext context, int diff) async {
    final bloc = context.read<ReconcileBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Adjustment?'),
        content: Text(
          'This will add a ${diff > 0 ? 'income' : 'expense'} transaction of '
          '${_fmtDiff(diff)} to balance your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      bloc.add(const ReconcileConfirmed(createAdjustment: true));
    }
  }
}
