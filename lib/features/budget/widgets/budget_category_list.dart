import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/budget/bloc/budget_bloc.dart';
import 'package:envelope/features/budget/widgets/allocation_sheet.dart';
import 'package:envelope/features/budget/widgets/category_group_header.dart';
import 'package:envelope/features/budget/widgets/category_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';


/// Scrollable category list for the budget screen.
///
/// Renders each visible [CategoryGroup] as a collapsible section using
/// [SliverList]s inside a [CustomScrollView]. Collapse state is managed
/// locally per group so switching months does not reset it.
class BudgetCategoryList extends StatefulWidget {
  const BudgetCategoryList({required this.state, super.key});

  final BudgetLoaded state;

  @override
  State<BudgetCategoryList> createState() => _BudgetCategoryListState();
}

class _BudgetCategoryListState extends State<BudgetCategoryList> {
  /// groupId → whether the group is currently expanded.
  final Map<String, bool> _expanded = {};

  // Cached derived data — rebuilt in initState and didUpdateWidget to avoid
  // sorting and map-building on every collapse toggle.
  late List<CategoryGroup> _visibleGroups;
  late Map<String, List<Category>> _categoriesByGroup;
  late Map<String, BudgetEntry> _entryByCategory;

  @override
  void initState() {
    super.initState();
    _rebuildDerived(widget.state);
  }

  @override
  void didUpdateWidget(BudgetCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _rebuildDerived(widget.state);
      // Prune expand-state entries for groups that no longer exist.
      final currentIds = widget.state.groups.map((g) => g.id).toSet();
      _expanded.removeWhere((id, _) => !currentIds.contains(id));
    }
  }

  void _rebuildDerived(BudgetLoaded state) {
    _visibleGroups = state.groups
        .where((g) => !g.isHidden)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    _categoriesByGroup = <String, List<Category>>{};
    for (final cat in state.categories) {
      (_categoriesByGroup[cat.groupId] ??= []).add(cat);
    }
    for (final cats in _categoriesByGroup.values) {
      cats.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    }

    _entryByCategory = {
      for (final e in state.entries) e.categoryId: e,
    };
  }

  bool _isExpanded(String groupId) => _expanded[groupId] ?? true;

  void _toggle(String groupId) {
    setState(() => _expanded[groupId] = !_isExpanded(groupId));
  }

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[
      const _ColumnHeaders(),
      for (final group in _visibleGroups) ...[
        _buildGroupHeader(group),
        if (_isExpanded(group.id))
          _buildCategorySliver(_categoriesByGroup[group.id] ?? []),
      ],
      // Bottom padding so the FAB doesn't cover the last row.
      const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
    ];

    return CustomScrollView(slivers: slivers);
  }

  Widget _buildGroupHeader(CategoryGroup group) {
    final cats = _categoriesByGroup[group.id] ?? [];
    final totalAvailable = cats.fold<int>(
      0,
      (sum, c) => sum + (_entryByCategory[c.id]?.available ?? 0),
    );

    return SliverToBoxAdapter(
      child: CategoryGroupHeader(
        name: group.name,
        totalAvailable: totalAvailable,
        isExpanded: _isExpanded(group.id),
        onToggle: () => _toggle(group.id),
      ),
    );
  }

  Widget _buildCategorySliver(List<Category> cats) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cat = cats[index];
          return CategoryRow(
            category: cat,
            entry: _entryByCategory[cat.id],
            onBudgetedTap: () => _showAllocationSheet(context, cat),
          );
        },
        childCount: cats.length,
      ),
    );
  }

  Future<void> _showAllocationSheet(
    BuildContext context,
    Category category,
  ) async {
    final currentBudgeted = _entryByCategory[category.id]?.budgeted ?? 0;
    final newBudgeted = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => AllocationSheet(
        category: category,
        currentBudgeted: currentBudgeted,
      ),
    );
    if (newBudgeted == null || !context.mounted) return;
    context.read<BudgetBloc>().add(
      BudgetEntryAllocated(
        categoryId: category.id,
        month: widget.state.month,
        year: widget.state.year,
        budgeted: newBudgeted,
      ),
    );
  }
}

/// Sticky column-header row for the three amount columns.
class _ColumnHeaders extends StatelessWidget {
  const _ColumnHeaders();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(
          children: [
            const Expanded(flex: 3, child: SizedBox.shrink()),
            SizedBox(
              width: kBudgetAmountColumnWidth,
              child: Text('Budgeted', textAlign: TextAlign.end, style: style),
            ),
            SizedBox(
              width: kBudgetAmountColumnWidth,
              child: Text('Spent', textAlign: TextAlign.end, style: style),
            ),
            SizedBox(
              width: kBudgetAmountColumnWidth,
              child: Text('Available', textAlign: TextAlign.end, style: style),
            ),
          ],
        ),
      ),
    );
  }
}
