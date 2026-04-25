import 'financial_entity.dart';

enum CategoryType { expense, income }

class Subcategory {
  final int id;
  final String name;
  final String? iconName;

  Subcategory({
    required this.id,
    required this.name,
    this.iconName,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconName: json['iconName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'iconName': iconName,
    };
  }
}

class Category {
  final int id;
  final String name;
  final String? iconName;
  final CategoryType type;
  final List<Subcategory> subcategories;
  final FinancialEntity? financialEntity;

  Category({
    required this.id,
    required this.name,
    this.iconName,
    required this.type,
    this.subcategories = const [],
    this.financialEntity,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      iconName: json['iconName'],
      type: json['type'] == 'INCOME' ? CategoryType.income : CategoryType.expense,
      subcategories: (json['subcategories'] as List?)
          ?.map((s) => Subcategory.fromJson(s))
          .toList() ?? [],
      financialEntity: json['financialEntity'] != null 
          ? FinancialEntity.fromJson(json['financialEntity']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'iconName': iconName,
      'type': type == CategoryType.income ? 'INCOME' : 'EXPENSE',
      if (financialEntity != null) 'financialEntity': financialEntity!.toJson(),
    };
  }
}
