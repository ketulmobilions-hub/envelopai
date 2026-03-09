import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';

/// Result returned by [MoveMoneySheet] on successful save.
typedef MoveMoneyResult = ({
  String fromCategoryId,
  String toCategoryId,
  int amount,
});

/// Modal bottom sheet for transferring budget between two categories.
///
/// Pops with a [MoveMoneyResult] in minor currency units on confirm, or
/// `null` if the user dismisses without saving.
///
/// Requires at least two categories — renders a disabled form with an
/// explanatory message when [categories] has fewer than two entries.
class MoveMoneySheet extends StatefulWidget {
  const MoveMoneySheet({required this.categories, super.key});

  /// All visible categories available as transfer source or destination.
  final List<Category> categories;

  @override
  State<MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<MoveMoneySheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _fromId;
  String? _toId;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  /// Parses a user-entered currency string (strips `$`, commas, whitespace)
  /// and returns the value as a positive double, or `null` if invalid.
  static double? _parseAmount(String? raw) {
    final cleaned =
        (raw ?? '').replaceAll(r'$', '').replaceAll(',', '').trim();
    final value = double.tryParse(cleaned);
    return (value != null && value > 0) ? value : null;
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final fromId = _fromId;
    final toId = _toId;
    if (fromId == null || toId == null) return;
    // Multiply then round to avoid floating-point drift (e.g. 0.1 + 0.2).
    final value = _parseAmount(_amountController.text);
    if (value == null) return;
    Navigator.of(context).pop<MoveMoneyResult>((
      fromCategoryId: fromId,
      toCategoryId: toId,
      amount: (value * 100).round(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasEnoughCategories = widget.categories.length >= 2;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: hasEnoughCategories ? _buildForm(theme) : _buildEmpty(theme),
    );
  }

  Widget _buildForm(ThemeData theme) => Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Move Money', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'From',
                border: OutlineInputBorder(),
              ),
              initialValue: _fromId,
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (id) => setState(() {
                _fromId = id;
                // Reset "to" if it matches the new "from".
                if (_toId == id) _toId = null;
              }),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'To',
                border: OutlineInputBorder(),
              ),
              initialValue: _toId,
              items: widget.categories
                  .where((c) => c.id != _fromId)
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (id) => setState(() => _toId = id),
              validator: (v) => v == null ? 'Select a category' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: r'$',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  _parseAmount(v) == null ? 'Enter a positive amount' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Move'),
              ),
            ),
          ],
        ),
      );

  Widget _buildEmpty(ThemeData theme) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Move Money', style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          Text(
            'Add at least two categories before moving money.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
        ],
      );
}
