import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sticky banner showing the To-Be-Budgeted (TBB) amount.
///
/// Colour-coded:
/// - Green  → [tbb] > 0: money available to assign ("Ready to Assign")
/// - Grey   → [tbb] = 0: fully assigned ("All Money Assigned")
/// - Red    → [tbb] < 0: over-budgeted ("Overspent")
class TbbBanner extends StatelessWidget {
  const TbbBanner({required this.tbb, super.key});

  /// Amount in minor currency units (e.g. cents).
  final int tbb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final Color bgColor;
    final String label;

    if (tbb > 0) {
      bgColor = colorScheme.primaryContainer;
      label = 'Ready to Assign';
    } else if (tbb < 0) {
      bgColor = colorScheme.errorContainer;
      label = 'Overspent';
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      label = 'All Money Assigned';
    }

    final textColor = theme.colorScheme.onSurface;
    final amountText =
        NumberFormat.currency(symbol: r'$').format(tbb / 100);

    return ColoredBox(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(color: textColor),
            ),
            Text(
              amountText,
              style: theme.textTheme.titleLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
