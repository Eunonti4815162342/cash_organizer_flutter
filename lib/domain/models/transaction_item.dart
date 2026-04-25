import 'account_item.dart';
import 'category.dart';
import 'beneficiary.dart';

enum TransactionType { EXPENSE, INCOME, TRANSFER }

class TransactionItem {
  final int id;
  final String date;
  final String description;
  final Amount amount;
  final AccountItem account;
  final Category? category;
  final Subcategory? subcategory;
  final Beneficiary? beneficiary;
  final AccountItem? toAccount;
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
    this.subcategory,
    this.beneficiary,
    this.toAccount,
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
      subcategory: json['subcategory'] != null ? Subcategory.fromJson(json['subcategory']) : null,
      beneficiary: json['beneficiary'] != null ? Beneficiary.fromJson(json['beneficiary']) : null,
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
