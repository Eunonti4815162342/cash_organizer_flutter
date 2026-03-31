enum EntityType { PHYSICAL, LEGAL }

class FinancialEntity {
  final int id;
  final String name;
  final String? taxId;
  final String? description;
  final EntityType type;

  FinancialEntity({
    required this.id,
    required this.name,
    this.taxId,
    this.description,
    required this.type,
  });

  factory FinancialEntity.fromJson(Map<String, dynamic> json) {
    return FinancialEntity(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      taxId: json['taxId'],
      description: json['description'],
      type: json['type'] == 'LEGAL' ? EntityType.LEGAL : EntityType.PHYSICAL,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id == 0 ? null : id,
      'name': name,
      'taxId': taxId,
      'description': description,
      'type': type == EntityType.LEGAL ? 'LEGAL' : 'PHYSICAL',
    };
  }
}
