import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';

/// Modal bottom sheet for setting a category's budgeted amount.
///
/// Pops with the new amount in minor currency units (cents) when the user
/// confirms, or with `null` if they dismiss without saving.
class AllocationSheet extends StatefulWidget {
  const AllocationSheet({
    required this.category,
    required this.currentBudgeted,
    super.key,
  });

  final Category category;

  /// Current budgeted amount in minor currency units.
  final int currentBudgeted;

  @override
  State<AllocationSheet> createState() => _AllocationSheetState();
}

class _AllocationSheetState extends State<AllocationSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: (widget.currentBudgeted / 100).toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    // Strip currency symbol, commas, and surrounding whitespace to handle
    // pasted values like "$1,500.00".
    final raw = _controller.text
        .replaceAll(r'$', '')
        .replaceAll(',', '')
        .trim();
    final value = double.tryParse(raw);
    if (value == null || value < 0) return;
    // Multiply then round to avoid floating-point drift (e.g. 0.1 + 0.2).
    Navigator.of(context).pop((value * 100).round());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.category.name, style: theme.textTheme.titleMedium),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Budgeted',
              prefixText: r'$',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
  }
}
