class TransactionFilters {
  final String? startDate;
  final String? endDate;
  final List<int>? accountIds;
  final List<int>? categoryIds;
  final List<int>? subcategoryIds;
  final List<int>? beneficiaryIds;
  final bool groupBySubcategory;
  final int page;
  final int size;

  const TransactionFilters({
    this.startDate,
    this.endDate,
    this.accountIds,
    this.categoryIds,
    this.subcategoryIds,
    this.beneficiaryIds,
    this.groupBySubcategory = false,
    this.page = 0,
    this.size = 20,
  });

  /// Permite crear una copia modificada (Patrón Inmutable)
  TransactionFilters copyWith({
    String? startDate,
    String? endDate,
    List<int>? accountIds,
    List<int>? categoryIds,
    List<int>? subcategoryIds,
    List<int>? beneficiaryIds,
    bool? groupBySubcategory,
    int? page,
    int? size,
  }) {
    return TransactionFilters(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      accountIds: accountIds ?? this.accountIds,
      categoryIds: categoryIds ?? this.categoryIds,
      subcategoryIds: subcategoryIds ?? this.subcategoryIds,
      beneficiaryIds: beneficiaryIds ?? this.beneficiaryIds,
      groupBySubcategory: groupBySubcategory ?? this.groupBySubcategory,
      page: page ?? this.page,
      size: size ?? this.size,
    );
  }

  bool get isEmpty => 
    startDate == null && 
    endDate == null && 
    (accountIds?.isEmpty ?? true) && 
    (categoryIds?.isEmpty ?? true) && 
    (subcategoryIds?.isEmpty ?? true) && 
    (beneficiaryIds?.isEmpty ?? true);
}
