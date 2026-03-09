import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A single row in the transaction list.
class TransactionRow extends StatelessWidget {
  const TransactionRow({
    required this.transaction,
    required this.categoryNames,
    super.key,
  });

  static final _fmt = NumberFormat.currency(symbol: r'$');

  final Transaction transaction;

  /// Maps categoryId → category name (from bloc state).
  final Map<String, String> categoryNames;

  String get _categoryLabel {
    return switch (transaction.type) {
      TransactionType.income => 'Inflow',
      TransactionType.transfer => transaction.amount < 0
          ? 'Transfer to ${transaction.payee}'
          : 'Transfer from ${transaction.payee}',
      TransactionType.expense => transaction.categoryId != null
          ? (categoryNames[transaction.categoryId] ?? 'Unknown Category')
          : '(No Category)',
    };
  }

  static String _fmtAmount(int cents) => _fmt.format(cents.abs() / 100);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInflow = transaction.amount > 0;
    final amountColor =
        isInflow ? theme.colorScheme.primary : theme.colorScheme.error;
    final amountPrefix = isInflow ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Cleared indicator
          Icon(
            transaction.cleared
                ? Icons.check_circle
                : Icons.radio_button_unchecked,
            size: 16,
            color: transaction.cleared
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
          const SizedBox(width: 12),
          // Payee + category
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.payee,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _categoryLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Text(
            '$amountPrefix${_fmtAmount(transaction.amount)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: amountColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
