import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:envelope/features/transactions/widgets/category_picker_sheet.dart';
import 'package:envelope/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Full-screen form for adding a new transaction or editing an existing one.
///
/// Pass [transactionId] to load an existing transaction for editing.
/// Pass [initialAccountId] to pre-select an account for a new transaction.
class AddEditTransactionScreen extends StatelessWidget {
  const AddEditTransactionScreen({
    super.key,
    this.transactionId,
    this.initialAccountId,
  });

  final String? transactionId;
  final String? initialAccountId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TransactionFormBloc>()
        ..add(
          TransactionFormStarted(
            transactionId: transactionId,
            initialAccountId: initialAccountId,
          ),
        ),
      child: _AddEditTransactionView(
        isEditing: transactionId != null,
        initialAccountId: initialAccountId,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal stateful view
// ---------------------------------------------------------------------------

class _AddEditTransactionView extends StatefulWidget {
  const _AddEditTransactionView({
    required this.isEditing,
    this.initialAccountId,
  });

  final bool isEditing;
  final String? initialAccountId;

  @override
  State<_AddEditTransactionView> createState() =>
      _AddEditTransactionViewState();
}

class _AddEditTransactionViewState extends State<_AddEditTransactionView> {
  static final _dateFmt = DateFormat.yMMMd();
  static final _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  final _memoController = TextEditingController();

  bool _isInflow = false; // false = expense/outflow, true = income/inflow
  // Stored in local time for display; converted to UTC on submit via .toUtc().
  DateTime _selectedDate = DateTime.now().toLocal();
  String? _selectedAccountId;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _cleared = false;

  /// Set to true after the first time Save is tapped, so category validation
  /// error is only shown after an attempted submit.
  bool _submitted = false;

  /// Whether form fields have been populated from an existing transaction.
  bool _initialized = false;

  @override
  void dispose() {
    _amountController.dispose();
    _payeeController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _initFromTransaction(Transaction t, List<Category> cats) {
    _isInflow = t.amount >= 0;
    _amountController.text = (t.amount.abs() / 100).toStringAsFixed(2);
    _selectedDate = t.date.toLocal();
    _selectedAccountId = t.accountId;
    _payeeController.text = t.payee;
    _selectedCategoryId = t.categoryId;
    _selectedCategoryName =
        cats
            .where((c) => c.id == t.categoryId)
            .map((c) => c.name)
            .firstOrNull;
    _cleared = t.cleared;
    _memoController.text = t.memo ?? '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && mounted) setState(() => _selectedDate = picked);
  }

  Future<void> _pickCategory(TransactionFormReady state) async {
    final result = await CategoryPickerSheet.show(
      context,
      groups: state.groups,
      categories: state.categories,
      selectedId: _selectedCategoryId,
    );
    if (result == null || !mounted) return;
    setState(() {
      _selectedCategoryId = result.id;
      _selectedCategoryName = result.name;
    });
  }

  void _submit(TransactionFormReady state) {
    setState(() => _submitted = true);

    final formValid = _formKey.currentState?.validate() ?? false;
    final categoryValid = _isInflow || _selectedCategoryId != null;
    if (!formValid || !categoryValid) return;

    final accountId = _selectedAccountId;
    if (accountId == null) return; // guarded by form validator above

    final raw = double.tryParse(_amountController.text) ?? 0;
    final amountCents = (raw * 100).round();
    final signedAmount = _isInflow ? amountCents : -amountCents;
    final now = DateTime.now().toUtc();
    final existing = state.existing;
    final memo = _memoController.text.trim();

    final transaction = Transaction(
      id: existing?.id ?? _uuid.v4(),
      accountId: accountId,
      categoryId: _isInflow ? null : _selectedCategoryId,
      payee: _payeeController.text.trim(),
      amount: signedAmount,
      date: _selectedDate.toUtc(),
      memo: memo.isEmpty ? null : memo,
      cleared: _cleared,
      type: _isInflow ? TransactionType.income : TransactionType.expense,
      transferPairId: existing?.transferPairId,
      updatedAt: now,
      isDeleted: false,
    );

    context
        .read<TransactionFormBloc>()
        .add(TransactionFormSubmitted(transaction: transaction));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TransactionFormBloc, TransactionFormState>(
      listener: (context, state) {
        if (state is TransactionFormReady && !_initialized) {
          if (state.existing != null) {
            _initFromTransaction(state.existing!, state.categories);
          } else {
            // Pre-select account: prefer initialAccountId, fall back to first.
            _selectedAccountId =
                widget.initialAccountId ??
                (state.accounts.isNotEmpty ? state.accounts.first.id : null);
          }
          setState(() => _initialized = true);
          return;
        }
        if (state is TransactionFormReady && state.saveError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.saveError!)),
          );
          return;
        }
        if (state is TransactionFormSaved) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return switch (state) {
          TransactionFormInitial() || TransactionFormLoading() => Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing ? 'Edit Transaction' : 'Add Transaction',
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          ),
          TransactionFormError(:final message) => Scaffold(
            appBar: AppBar(
              title: Text(
                widget.isEditing ? 'Edit Transaction' : 'Add Transaction',
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          TransactionFormReady() => _buildForm(context, state),
          // The listener pops the route when Saved is emitted; this arm
          // is never visible but required for exhaustive matching.
          TransactionFormSaved() => const SizedBox.shrink(),
        };
      },
    );
  }

  Widget _buildForm(BuildContext context, TransactionFormReady state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Resolve category name for display (handles edit-load case).
    final categoryDisplay =
        _selectedCategoryName ??
        state.categories
            .where((c) => c.id == _selectedCategoryId)
            .map((c) => c.name)
            .firstOrNull;

    final showCategoryError =
        _submitted && !_isInflow && _selectedCategoryId == null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEditing ? 'Edit Transaction' : 'Add Transaction',
        ),
        actions: [
          TextButton(
            onPressed: state.isSubmitting ? null : () => _submit(state),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            // ---- Inflow / Outflow toggle ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Outflow'),
                    icon: Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Inflow'),
                    icon: Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_isInflow},
                onSelectionChanged: (s) =>
                    setState(() => _isInflow = s.first),
              ),
            ),

            // ---- Amount ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  // TODO(#57): Replace with a custom TextInputFormatter that
                  // validates the full string, preventing sequences like '..'.
                  // FilteringTextInputFormatter.allow uses the regex as a
                  // per-character allowlist, so anchors have no effect.
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[0-9.]'),
                  ),
                ],
                style: theme.textTheme.headlineMedium,
                decoration: InputDecoration(
                  prefixText: r'$ ',
                  prefixStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  hintText: '0.00',
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Enter an amount';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
            ),

            const Divider(),

            // ---- Date ----
            ListTile(
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Date'),
              trailing: Text(
                _dateFmt.format(_selectedDate),
                style: theme.textTheme.bodyLarge,
              ),
              onTap: _pickDate,
            ),

            const Divider(height: 1),

            // ---- Account ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: DropdownButtonFormField<String>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Account',
                  prefixIcon: Icon(Icons.credit_card_outlined),
                  border: InputBorder.none,
                ),
                items: state.accounts
                    .map(
                      (a) => DropdownMenuItem(
                        value: a.id,
                        child: Text(a.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedAccountId = v),
                validator: (v) => v == null ? 'Select an account' : null,
              ),
            ),

            const Divider(height: 1),

            // ---- Payee ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _payeeController,
                decoration: const InputDecoration(
                  labelText: 'Payee',
                  prefixIcon: Icon(Icons.store_outlined),
                  border: InputBorder.none,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a payee' : null,
              ),
            ),

            const Divider(height: 1),

            // ---- Category (outflow only) ----
            if (!_isInflow) ...[
              ListTile(
                leading: Icon(
                  Icons.category_outlined,
                  color: showCategoryError ? colorScheme.error : null,
                ),
                title: Text(
                  'Category',
                  style: showCategoryError
                      ? TextStyle(color: colorScheme.error)
                      : null,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      categoryDisplay ?? 'Select category',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: categoryDisplay == null
                            ? (showCategoryError
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => _pickCategory(state),
              ),
              if (showCategoryError)
                Padding(
                  padding: const EdgeInsets.only(left: 72, bottom: 4),
                  child: Text(
                    'Select a category',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                    ),
                  ),
                ),
              const Divider(height: 1),
            ],

            // ---- Memo ----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(
                  labelText: 'Memo (optional)',
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: InputBorder.none,
                ),
              ),
            ),

            const Divider(height: 1),

            // ---- Cleared ----
            SwitchListTile(
              secondary: const Icon(Icons.check_circle_outline),
              title: const Text('Cleared'),
              value: _cleared,
              onChanged: (v) => setState(() => _cleared = v),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
