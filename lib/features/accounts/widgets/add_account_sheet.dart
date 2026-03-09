import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

const Uuid _uuid = Uuid();

/// Display names used in the type dropdown.
const Map<AccountType, String> _typeLabels = {
  AccountType.checking: 'Checking',
  AccountType.savings: 'Savings',
  AccountType.creditCard: 'Credit Card',
  AccountType.cash: 'Cash',
};

/// Bottom sheet form for adding a new account.
///
/// Pops with the constructed [Account] on save, or `null` when dismissed.
class AddAccountSheet extends StatefulWidget {
  const AddAccountSheet({super.key});

  @override
  State<AddAccountSheet> createState() => _AddAccountSheetState();
}

class _AddAccountSheetState extends State<AddAccountSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  AccountType _type = AccountType.checking;
  bool _onBudget = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final balanceText = _balanceCtrl.text.trim();
    final balanceDollars = double.tryParse(balanceText) ?? 0.0;
    final balanceCents = (balanceDollars * 100).round();

    final account = Account(
      id: _uuid.v4(),
      name: _nameCtrl.text.trim(),
      type: _type,
      balance: balanceCents,
      clearedBalance: balanceCents,
      currency: 'USD',
      onBudget: _onBudget,
    );

    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Add Account', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Account name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AccountType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Account type',
                border: OutlineInputBorder(),
              ),
              items: AccountType.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(_typeLabels[t]!),
                    ),
                  )
                  .toList(),
              onChanged: (t) => setState(() => _type = t!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _balanceCtrl,
              decoration: const InputDecoration(
                labelText: 'Starting balance',
                prefixText: r'$',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a balance';
                final parsed = double.tryParse(v.trim());
                if (parsed == null) return 'Enter a valid amount';
                return null;
              },
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _onBudget,
              onChanged: (v) => setState(() => _onBudget = v),
              title: const Text('On budget'),
              subtitle: const Text(
                'Transactions affect your To Be Budgeted amount',
              ),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _save, child: const Text('Add Account')),
          ],
        ),
      ),
    );
  }
}
