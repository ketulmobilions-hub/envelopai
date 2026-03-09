import 'package:envelope/domain/models/models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Column widths shared between [AccountRow] and [AccountColumnHeader].
const _kClearedWidth = 72.0;
const _kUnclearedWidth = 80.0;
const _kTotalWidth = 72.0;

/// Thin header row rendered once per account section (budget / tracking).
/// Shows section [title] on the left and column labels on the right.
class AccountColumnHeader extends StatelessWidget {
  const AccountColumnHeader({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(
            width: _kClearedWidth,
            child: Text('Cleared', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: _kUnclearedWidth,
            child:
                Text('Uncleared', style: style, textAlign: TextAlign.right),
          ),
          SizedBox(
            width: _kTotalWidth,
            child: Text('Total', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

/// A single row showing one [account]'s name, type, and three balances.
class AccountRow extends StatelessWidget {
  const AccountRow({required this.account, super.key});

  static final _fmt = NumberFormat.currency(symbol: r'$');

  final Account account;

  static String _fmtCents(int cents) => _fmt.format(cents / 100);

  static String _typeLabel(AccountType type) => switch (type) {
        AccountType.checking => 'Checking',
        AccountType.savings => 'Savings',
        AccountType.creditCard => 'Credit Card',
        AccountType.cash => 'Cash',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cleared = account.clearedBalance;
    final uncleared = account.balance - account.clearedBalance;
    final total = account.balance;

    TextStyle amountStyle(int value) => theme.textTheme.bodyMedium!.copyWith(
          color: value < 0 ? theme.colorScheme.error : null,
        );

    return InkWell(
      onTap: () {}, // placeholder — account detail in issue 4.3
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _typeLabel(account.type),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: _kClearedWidth,
              child: Text(
                _fmtCents(cleared),
                style: amountStyle(cleared),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: _kUnclearedWidth,
              child: Text(
                _fmtCents(uncleared),
                style: amountStyle(uncleared),
                textAlign: TextAlign.right,
              ),
            ),
            SizedBox(
              width: _kTotalWidth,
              child: Text(
                _fmtCents(total),
                style: amountStyle(total).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
