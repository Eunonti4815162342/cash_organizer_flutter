import 'account_item.dart';
import 'category.dart';

enum TransactionType { EXPENSE, INCOME, TRANSFER }

class TransactionItem {
  final int id;
  final String date;
  final String description;
  final Amount amount;
  final AccountItem account;
  final Category? category;
  final AccountItem? toAccount;
  final TransactionType type;
  final String? notes;
  final int? statusFlags;
  final bool isScheduled;
  final bool isHeader;
  final List<String> tags;

  TransactionItem({
    required this.id,
    required this.date,
    required this.description,
    required this.amount,
    required this.account,
    this.category,
    this.toAccount,
    required this.type,
    this.notes,
    this.statusFlags,
    required this.isScheduled,
    required this.isHeader,
    required this.tags,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] ?? 0,
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      amount: Amount.fromJson(json['amount'] ?? {}),
      account: AccountItem.fromJson(json['account'] ?? {}),
      category: json['category'] != null ? Category.fromJson(json['category']) : null,
      toAccount: json['toAccount'] != null ? AccountItem.fromJson(json['toAccount']) : null,
      type: TransactionType.values.firstWhere(
        (e) => e.name == (json['type'] ?? 'EXPENSE'),
        orElse: () => TransactionType.EXPENSE,
      ),
      notes: json['notes'],
      statusFlags: json['statusFlags'],
      isScheduled: json['isScheduled'] ?? false,
      isHeader: json['isHeader'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}