import 'package:equatable/equatable.dart';

enum TransactionType { income, expense, transfer }

class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.payee,
    required this.amount,
    required this.date,
    required this.cleared,
    required this.type,
    required this.updatedAt,
    required this.isDeleted,
    this.categoryId,
    this.memo,
    this.transferPairId,
  }) : assert(
         type != TransactionType.transfer || categoryId == null,
         'transfer transactions must have a null categoryId',
       ),
       assert(
         type != TransactionType.transfer || transferPairId != null,
         'transfer transactions must have a transferPairId',
       );

  final String id;
  final String accountId;

  /// null for transfers (no budget category).
  final String? categoryId;

  final String payee;

  /// Positive = inflow, negative = outflow, in minor currency units (e.g.
  /// cents).
  final int amount;

  /// Always UTC.
  final DateTime date;

  final String? memo;
  final bool cleared;
  final TransactionType type;

  /// Links the two legs of a transfer.
  final String? transferPairId;

  /// Always UTC.
  final DateTime updatedAt;

  /// Soft-delete flag used by the sync layer.
  final bool isDeleted;

  Transaction copyWith({
    String? id,
    String? accountId,
    String? categoryId,
    String? payee,
    int? amount,
    DateTime? date,
    String? memo,
    bool? cleared,
    TransactionType? type,
    String? transferPairId,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      payee: payee ?? this.payee,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      cleared: cleared ?? this.cleared,
      type: type ?? this.type,
      transferPairId: transferPairId ?? this.transferPairId,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
    id,
    accountId,
    categoryId,
    payee,
    amount,
    date,
    memo,
    cleared,
    type,
    transferPairId,
    updatedAt,
    isDeleted,
  ];
}
