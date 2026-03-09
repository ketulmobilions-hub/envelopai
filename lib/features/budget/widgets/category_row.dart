import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Width of each monetary amount column, kept in sync with `_ColumnHeaders` in
/// `budget_category_list.dart`.
const _kAmountColumnWidth = 72.0;

/// A single category row in the budget screen.
///
/// Displays the category name alongside its budgeted, spent (activity), and
/// available amounts for the current month. Available is colour-coded:
/// green (>= 0) or red (< 0 / overspent).
class CategoryRow extends StatelessWidget {
  const CategoryRow({
    required this.category,
    this.entry,
    super.key,
  });

  final Category category;

  /// The budget entry for the current month, or `null` if none exists yet.
  final BudgetEntry? entry;

  static final _fmt = NumberFormat.currency(symbol: r'$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final budgeted = entry?.budgeted ?? 0;
    final activity = entry?.activity ?? 0;
    final available = entry?.available ?? 0;

    final availableColor = available < 0
        ? theme.colorScheme.error
        : theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              category.name,
              style: theme.textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _AmountCell(
            label: _fmt.format(budgeted / 100),
            color: theme.colorScheme.onSurface,
          ),
          _AmountCell(
            label: _fmt.format(activity / 100),
            color: theme.colorScheme.onSurfaceVariant,
          ),
          _AmountCell(
            label: _fmt.format(available / 100),
            color: availableColor,
            isBold: true,
          ),
        ],
      ),
    );
  }
}

class _AmountCell extends StatelessWidget {
  const _AmountCell({
    required this.label,
    required this.color,
    this.isBold = false,
  });

  final String label;
  final Color color;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kAmountColumnWidth,
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
