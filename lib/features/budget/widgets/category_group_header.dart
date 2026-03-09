import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Sticky sliver header for a category group row.
///
/// Shows the group name and the sum of all available amounts in the group.
/// Tapping toggles expansion of the category rows beneath it.
class CategoryGroupHeader extends StatelessWidget {
  const CategoryGroupHeader({
    required this.name,
    required this.totalAvailable,
    required this.isExpanded,
    required this.onToggle,
    super.key,
  });

  final String name;

  /// Sum of `available` for all categories in this group, in minor currency
  /// units.
  final int totalAvailable;

  final bool isExpanded;
  final VoidCallback onToggle;

  static final _fmt = NumberFormat.currency(symbol: r'$');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableColor = totalAvailable < 0
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            AnimatedRotation(
              turns: isExpanded ? 0 : 0.5,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.expand_less,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                name.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              _fmt.format(totalAvailable / 100),
              style: theme.textTheme.bodySmall?.copyWith(
                color: availableColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
