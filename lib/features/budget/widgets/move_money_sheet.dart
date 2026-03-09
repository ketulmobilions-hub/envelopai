import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
///
/// [availableByCategoryId] maps each category id to its available balance in
/// minor currency units. Used to prevent the user from moving more than what
/// is available in the selected "from" category. Capping against `available`
/// (not `budgeted`) handles post-rollover entries whose `budgeted` may be
/// negative.
class MoveMoneySheet extends StatefulWidget {
  const MoveMoneySheet({
    required this.categories,
    required this.availableByCategoryId,
    super.key,
  });

  /// All visible categories available as transfer source or destination.
  final List<Category> categories;

  /// Available balance (minor currency units) keyed by category id.
  final Map<String, int> availableByCategoryId;

  @override
  State<MoveMoneySheet> createState() => _MoveMoneySheetState();
}

class _MoveMoneySheetState extends State<MoveMoneySheet> {
  static final _fmt = NumberFormat.currency(symbol: r'$');

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

  String? _validateAmount(String? v) {
    final parsed = _parseAmount(v);
    if (parsed == null) return 'Enter a positive amount';
    final fromId = _fromId;
    // Require a From category before validating the cap so the user gets a
    // clear error rather than a silent pass.
    if (fromId == null) return 'Select a from category first';
    final maxCents = widget.availableByCategoryId[fromId] ?? 0;
    if (maxCents <= 0) return 'No funds available to move in this category';
    if ((parsed * 100).round() > maxCents) {
      return 'Only ${_fmt.format(maxCents / 100)} available in this category';
    }
    return null;
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
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
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
              onChanged: (id) {
                if (id == _fromId) return;
                setState(() => _toId = id);
              },
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
              validator: _validateAmount,
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
