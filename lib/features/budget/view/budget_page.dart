import 'package:envelope/features/budget/budget.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (_) => getIt<BudgetBloc>()
        ..add(BudgetMonthChanged(month: now.month, year: now.year)),
      child: const _BudgetView(),
    );
  }
}

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  static void _changeMonth(BuildContext context, int month, int year) {
    context
        .read<BudgetBloc>()
        .add(BudgetMonthChanged(month: month, year: year));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        final (month, year) = switch (state) {
          BudgetLoaded(:final month, :final year) => (month, year),
          // Default to current month — kept in sync with the initial event
          // dispatched in BudgetPage.
          _ => (DateTime.now().month, DateTime.now().year),
        };

        return Scaffold(
          appBar: AppBar(
            title: MonthNavigator(
              month: month,
              year: year,
              onPrevious: () {
                final prev = DateTime(year, month - 1);
                _changeMonth(context, prev.month, prev.year);
              },
              onNext: () {
                final next = DateTime(year, month + 1);
                _changeMonth(context, next.month, next.year);
              },
            ),
          ),
          body: switch (state) {
            BudgetInitial() || BudgetLoading() =>
              const Center(child: CircularProgressIndicator()),
            BudgetError(:final message) =>
              Center(child: Text('Error: $message')),
            BudgetLoaded(:final entries) => entries.isEmpty
                ? const Center(child: Text('No budget entries'))
                : ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      // TODO(3.3): resolve Category.name from categoryId
                      return ListTile(
                        title: Text(entry.categoryId),
                        trailing: Text(
                          '\$${(entry.available / 100).toStringAsFixed(2)}',
                        ),
                      );
                    },
                  ),
          },
        );
      },
    );
  }
}
