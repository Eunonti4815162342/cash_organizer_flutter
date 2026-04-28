class Beneficiary {
  final int id;
  final String name;
  final int? lastCategoryId;
  final int? lastSubcategoryId;
  final String? lastTransactionType;

  Beneficiary({
    required this.id, 
    required this.name,
    this.lastCategoryId,
    this.lastSubcategoryId,
    this.lastTransactionType,
  });

  factory Beneficiary.fromJson(Map<String, dynamic> json) {
    return Beneficiary(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      lastCategoryId: json['lastCategoryId'] ?? json['categoryId'],
      lastSubcategoryId: json['lastSubcategoryId'] ?? json['subcategoryId'],
      lastTransactionType: json['lastTransactionType'] ?? json['transactionType'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id == 0 ? null : id,
    'name': name,
    'lastCategoryId': lastCategoryId,
    'lastSubcategoryId': lastSubcategoryId,
    'lastTransactionType': lastTransactionType,
  };
}
