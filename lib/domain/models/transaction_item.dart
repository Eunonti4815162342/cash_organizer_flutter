import 'account_item.dart';

class TransactionItem {
  final int id;
  final String date;
  final String description;
  final Amount amount;
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
      notes: json['notes'],
      statusFlags: json['statusFlags'],
      isScheduled: json['isScheduled'] ?? false,
      isHeader: json['isHeader'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}