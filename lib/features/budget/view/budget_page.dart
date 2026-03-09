import 'package:envelope/features/budget/budget.dart';
import 'package:envelope/features/budget/widgets/move_money_sheet.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocProvider(
      create: (_) =>
          getIt<BudgetBloc>()
            ..add(BudgetMonthChanged(month: now.month, year: now.year)),
      child: const _BudgetView(),
    );
  }
}

class _BudgetView extends StatelessWidget {
  const _BudgetView();

  static void _changeMonth(BuildContext context, int month, int year) {
    context.read<BudgetBloc>().add(
      BudgetMonthChanged(month: month, year: year),
    );
  }

  static Future<void> _showMoveMoneySheet(
    BuildContext context,
    BudgetLoaded state,
  ) async {
    final result = await showModalBottomSheet<MoveMoneyResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => MoveMoneySheet(
        categories: state.categories,
        // Snapshot at sheet-open time; the DAO enforces the ZBB invariant
        // if stream updates occur while the sheet is displayed.
        // categoryId is unique per month/year (DB constraint), so the
        // map spread never silently overwrites an entry.
        availableByCategoryId: {
          for (final e in state.entries) e.categoryId: e.available,
        },
      ),
    );
    if (result == null || !context.mounted) return;
    context.read<BudgetBloc>().add(
      BudgetMoneyMoved(
        fromCategoryId: result.fromCategoryId,
        toCategoryId: result.toCategoryId,
        month: state.month,
        year: state.year,
        amount: result.amount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetBloc, BudgetState>(
      builder: (context, state) {
        final (month, year) = switch (state) {
          BudgetLoaded(:final month, :final year) => (month, year),
          // Default to current month — kept in sync with the initial event
          // dispatched in BudgetPage.
          _ => () {
              final now = DateTime.now();
              return (now.month, now.year);
            }(),
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
          floatingActionButton: switch (state) {
            final BudgetLoaded s => FloatingActionButton.extended(
                onPressed: () => _showMoveMoneySheet(context, s),
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Move Money'),
              ),
            _ => null,
          },
          body: switch (state) {
            BudgetInitial() || BudgetLoading() =>
              const Center(child: CircularProgressIndicator()),
            BudgetError(:final message) =>
              Center(child: Text('Error: $message')),
            final BudgetLoaded loaded => Column(
                children: [
                  TbbBanner(tbb: loaded.tbb),
                  Expanded(child: BudgetCategoryList(state: loaded)),
                ],
              ),
          },
        );
      },
    );
  }
}
