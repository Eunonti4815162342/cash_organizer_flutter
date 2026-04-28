import 'financial_entity.dart';

class Amount {
  final int value;
  final String currency;
  final bool isNegative;

  Amount(this.value, this.currency, this.isNegative);

  factory Amount.fromJson(Map<String, dynamic> json) {
    return Amount(
      json['value'] ?? 0,
      json['currency'] ?? '',
      json['isNegative'] ?? json['negative'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value,
    'currency': currency,
    'isNegative': isNegative,
  };
}

abstract class AccountBase {
  int id;
  String name;
  Amount amount;
  FinancialEntity? entity;

  AccountBase({
    required this.id,
    required this.name,
    required this.amount,
    this.entity,
  });
}

enum AccountItemType {
  generic(1),
  saltedge(2),
  syncNow(4),
  inactive(8),
  unbalanced(16),
  closed(32);

  final int flagValue;

  const AccountItemType(this.flagValue);

  bool matches(int flags) {
    return (flagValue & flags) > 0;
  }
}

class AccountItem extends AccountBase {
  String? description;
  String? accountType;
  int flags;
  String? notes;
  int? accountOrder;

  AccountItem({
    required super.id,
    required super.name,
    required super.amount,
    super.entity,
    this.description,
    this.accountType,
    required this.flags,
    this.notes,
    this.accountOrder,
  });

  bool get isUnbalanced => AccountItemType.unbalanced.matches(flags);
  bool get isSaltedge => AccountItemType.saltedge.matches(flags);

  factory AccountItem.fromJson(Map<String, dynamic> json) {
    return AccountItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      amount: Amount.fromJson(json['amount'] ?? {}),
      entity: json['entity'] != null ? FinancialEntity.fromJson(json['entity']) : null,
      description: json['description'],
      accountType: json['accountType'],
      flags: json['flags'] ?? 0,
      notes: json['notes'],
      accountOrder: json['accountOrder'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'amount': amount.toJson(),
    if (entity != null) 'entity': entity!.toJson(),
    'description': description,
    'accountType': accountType,
    'flags': flags,
    'notes': notes,
    'accountOrder': accountOrder,
  };
}
