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
    _categoriesFuture = _apiService.fetchCategories();
  }

  void _showCategoryForm(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CategoryFormDialog(),
    ).then((_) {
      setState(() {
        _categoriesFuture = _apiService.fetchCategories();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // Toolbar superior
        Container(
          height: 45,
          color: AppColors.cardBackground,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterDropdown(l10n.allDates),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showCategoryForm(context),
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: Text(l10n.newCategory, style: const TextStyle(fontSize: 13, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const Spacer(),
              const Icon(Icons.settings_outlined, color: AppColors.secondaryText, size: 20),
            ],
          ),
        ),
        const Divider(height: 1),
        
        // Cabecera de la tabla
        Container(
          height: 30,
          color: AppColors.tableHeader,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.arrow_drop_down, size: 18),
              const SizedBox(width: 8),
              Text(l10n.categoryName, style: AppTextStyles.tableHeader),
              const Spacer(),
              Text(l10n.allDates, style: AppTextStyles.tableHeader),
            ],
          ),
        ),
        
        // Lista expandible
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

  Widget _buildFilterDropdown(String label) {
    return Row(
      children: [
        Text(label, style: AppTextStyles.sidebarItem),
        const Icon(Icons.arrow_drop_down, color: AppColors.secondaryText),
      ],
    );
  }

  Widget _buildCategoryTile(Category category, AppLocalizations l10n) {
    bool isExpense = category.type == CategoryType.expense;
    
    return Column(
      children: [
        Container(
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
              title: Text(
                category.name,
                style: AppTextStyles.bodyText,
              ),
              trailing: Text(
                isExpense ? l10n.expense : l10n.income,
                style: TextStyle(
                  fontSize: 12,
                  color: isExpense ? AppColors.expenseRed : AppColors.incomeGreen,
                  fontWeight: FontWeight.w500,
                ),
              ),
              children: category.subcategories
                  .map((sub) => _buildSubcategoryTile(sub))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryTile(Subcategory subcategory) {
    return Container(
      padding: const EdgeInsets.only(left: 40, top: 8, bottom: 8, right: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0))),
        color: Color(0xFFFAFAFA),
      ),
      child: Row(
        children: [
          const Icon(Icons.subdirectory_arrow_right, size: 14, color: Colors.grey),
          const SizedBox(width: 10),
          Text(subcategory.name, style: const TextStyle(fontSize: 13, color: AppColors.primaryText)),
        ],
      ),
    );
  }
}
