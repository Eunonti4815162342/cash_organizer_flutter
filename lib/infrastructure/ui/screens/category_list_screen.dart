import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../styles/app_styles.dart';
import '../../../domain/models/category.dart';
import '../../../services/api_service.dart';
import '../widgets/category_form_dialog.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Category>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _categoriesFuture = _apiService.fetchCategories();
    });
  }

  void _showCategoryForm({Category? category, Subcategory? subcategory, int? parentId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        category: category,
        subcategory: subcategory,
        parentCategoryId: parentId,
      ),
    ).then((saved) {
      if (saved == true) _refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Container(
          height: 45,
          color: AppColors.cardBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text('Categories', style: AppTextStyles.sidebarItemBold),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showCategoryForm(),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(l10n.newCategory, style: const TextStyle(fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.refresh, size: 20), onPressed: _refresh),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final categories = snapshot.data ?? [];
              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) => _buildCategoryTile(categories[index], l10n),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(Category category, AppLocalizations l10n) {
    bool isExpense = category.type == CategoryType.expense;
    
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            category.subcategories.isNotEmpty ? Icons.arrow_right : Icons.circle,
            size: 18,
            color: AppColors.secondaryText,
          ),
          title: Text(category.name, style: AppTextStyles.bodyText),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpense ? l10n.expense : l10n.income,
                style: TextStyle(fontSize: 12, color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 18, color: AppColors.primaryBlue),
                onPressed: () => _showCategoryForm(parentId: category.id),
                tooltip: 'Add Subcategory',
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                onPressed: () => _showCategoryForm(category: category),
                tooltip: 'Edit Category',
              ),
            ],
          ),
          children: category.subcategories
              .map((sub) => _buildSubcategoryTile(sub))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSubcategoryTile(Subcategory subcategory) {
    return Container(
      padding: const EdgeInsets.only(left: 40, top: 4, bottom: 4, right: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        color: Color(0xFFFAFAFA),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(child: Text(subcategory.name, style: const TextStyle(fontSize: 13))),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
            onPressed: () => _showCategoryForm(subcategory: subcategory),
            tooltip: 'Edit Subcategory',
          ),
        ],
      ),
    );
  }
}
