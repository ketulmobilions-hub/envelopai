import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Prominent card showing the total net worth across all on-budget accounts.
class NetWorthCard extends StatelessWidget {
  const NetWorthCard({required this.netWorth, super.key});

  static final _fmt = NumberFormat.currency(symbol: r'$');

  /// Net worth in minor currency units (cents).
  final int netWorth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNegative = netWorth < 0;
    final valueColor =
        isNegative ? theme.colorScheme.error : theme.colorScheme.primary;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Net Worth',
              style: theme.textTheme.titleMedium,
            ),
            Text(
              _fmt.format(netWorth / 100),
              style: theme.textTheme.titleLarge?.copyWith(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
