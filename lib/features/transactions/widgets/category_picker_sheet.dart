import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';

/// A bottom sheet that lets the user pick a [Category] from a grouped,
/// searchable list.
///
/// Pops with the selected [Category], or `null` if dismissed.
class CategoryPickerSheet extends StatefulWidget {
  const CategoryPickerSheet({
    super.key,
    required this.groups,
    required this.categories,
    this.selectedId,
  });

  final List<CategoryGroup> groups;
  final List<Category> categories;

  /// ID of the currently selected category, shown with a checkmark.
  final String? selectedId;

  @override
  State<CategoryPickerSheet> createState() => _CategoryPickerSheetState();

  /// Convenience helper — shows the sheet and returns the result.
  static Future<Category?> show(
    BuildContext context, {
    required List<CategoryGroup> groups,
    required List<Category> categories,
    String? selectedId,
  }) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        groups: groups,
        categories: categories,
        selectedId: selectedId,
      ),
    );
  }
}

class _CategoryPickerSheetState extends State<CategoryPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.categories
        : widget.categories
              .where(
                (c) => c.name.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    // Build a flat list: group header rows followed by their category rows.
    final items = <_ListItem>[];
    for (final group in widget.groups) {
      final groupCats =
          filtered.where((c) => c.groupId == group.id).toList()
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      if (groupCats.isEmpty) continue;
      items.add(_GroupHeader(group));
      for (final cat in groupCats) {
        items.add(_CategoryItem(cat));
      }
    }

    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: const InputDecoration(
                  hintText: 'Search categories',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (v) => setState(() {
                  _query = v;
                }),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: items.isEmpty
                  ? const Center(child: Text('No categories found'))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return switch (item) {
                          _GroupHeader(:final group) => ListTile(
                            dense: true,
                            title: Text(
                              group.name.toUpperCase(),
                              style: Theme.of(
                                context,
                              ).textTheme.labelSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _CategoryItem(:final category) => ListTile(
                            title: Text(category.name),
                            trailing: category.id == widget.selectedId
                                ? Icon(Icons.check, color: colorScheme.primary)
                                : null,
                            onTap: () => Navigator.of(context).pop(category),
                          ),
                        };
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Private sealed list-item types
// ---------------------------------------------------------------------------

sealed class _ListItem {
  const _ListItem();
}

final class _GroupHeader extends _ListItem {
  const _GroupHeader(this.group);
  final CategoryGroup group;
}

final class _CategoryItem extends _ListItem {
  const _CategoryItem(this.category);
  final Category category;
}
