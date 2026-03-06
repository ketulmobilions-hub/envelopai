import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A row with back/forward arrows and a centred month-year label.
///
/// Calls [onPrevious] / [onNext] when the user taps either arrow.
class MonthNavigator extends StatelessWidget {
  const MonthNavigator({
    required this.month,
    required this.year,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int month;
  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('MMMM yyyy').format(DateTime(year, month));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: onPrevious,
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: onNext,
        ),
      ],
    );
  }
}
