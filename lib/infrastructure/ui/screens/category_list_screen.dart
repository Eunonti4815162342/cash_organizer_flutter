import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:natave_flutter/l10n/app_localizations.dart';
import 'package:natave_flutter/infrastructure/ui/styles/app_styles.dart';
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/models/transaction_item.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/category_form_dialog.dart';
import 'package:natave_flutter/infrastructure/ui/widgets/ui_helpers.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});
  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late final ICategoryRepository _categoryRepo;
  late final ApiService _apiService;
  
  List<Category> _categories = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  // Guardamos el estado del scroll
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _categoryRepo = GetIt.instance.get<ICategoryRepository>();
    _apiService = GetIt.instance.get<ApiService>();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    
    try {
      final res = await _categoryRepo.fetchCategories();
      res.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      for (var cat in res) {
        cat.subcategories.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      }
      
      if (mounted) {
        setState(() {
          _categories = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
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
      if (saved == true) _loadData(silent: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = MediaQuery.of(context).size.width < AppDimens.mobileBreakpoint;

    final filtered = _categories.where((c) =>
      c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      c.subcategories.any((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase()))
    ).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      body: Column(
        children: [
          _buildHeader(l10n, isMobile),
          _buildSearchBar(l10n),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty 
                  ? (_searchQuery.isNotEmpty 
                      ? EmptyStateWidget(icon: Icons.search_off_rounded, title: 'Sin resultados', subtitle: 'No hay categorías para "$_searchQuery"')
                      : EmptyStateWidget(icon: Icons.category_outlined, title: l10n.noData, subtitle: 'Crea tu primera categoría', actionLabel: l10n.newCategory, onAction: () => _showCategoryForm()))
                  : ListView.builder(
                      controller: _scrollController, // Vinculamos el controlador
                      key: const PageStorageKey('category_list'), // Preservamos posición
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) => _buildCategoryCard(filtered[index], l10n, isMobile),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isMobile) {
    return Container(
      height: 65,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24),
      decoration: const BoxDecoration(color: AppColors.white, border: Border(bottom: BorderSide(color: AppColors.black12))),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 12),
          Text(l10n.categories.toUpperCase(), style: AppTextStyles.screenTitle),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showCategoryForm(),
            icon: const Icon(Icons.add, size: 16, color: AppColors.white),
            label: Text(l10n.newCategory.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(hintText: l10n.search, prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey), filled: true, fillColor: const Color(0xFFF8FAFB), contentPadding: const EdgeInsets.symmetric(vertical: 0), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ),
    );
  }

  Widget _buildCategoryCard(Category category, AppLocalizations l10n, bool isMobile) {
    bool isExpense = category.type == CategoryType.expense;
    Color statusColor = isExpense ? AppColors.expenseRed : AppColors.incomeGreen;

    return Container(
      key: ValueKey('cat_${category.id}'), // Ayuda a Flutter a identificar el widget tras el refresh
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: AppColors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(border: Border(left: BorderSide(color: statusColor, width: 4))),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              maintainState: true, // ¡CRÍTICO! Mantiene la categoría abierta tras refrescar
              initiallyExpanded: category.subcategories.isNotEmpty,
              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.folder_outlined, color: statusColor, size: 20)),
              title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryText, fontSize: 14)),
              subtitle: Row(children: [Text(isExpense ? l10n.expense.toUpperCase() : l10n.income.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor.withValues(alpha: 0.7))), if (category.financialEntity != null) ...[const Text('  •  ', style: TextStyle(color: Colors.grey, fontSize: 10)), Icon(Icons.account_balance_outlined, size: 10, color: Colors.grey.shade500), const SizedBox(width: 4), Text(category.financialEntity!.name.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600))]]),
              trailing: _buildActionButtons(category),
              children: [
                const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF0F0F0)),
                ...category.subcategories.map((sub) => _buildSubcategoryItem(sub, category.id, statusColor)),
                _buildAddSubcategoryButton(category.id, statusColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(Category category) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: () => _showCategoryForm(category: category)),
      IconButton(icon: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent.withValues(alpha: 0.5)), onPressed: () => _handleDeleteCategory(category)),
    ]);
  }

  Future<void> _handleDeleteCategory(Category category) async {
    final transactions = await _apiService.fetchTransactionsByCategory(category.id);
    if (transactions.isNotEmpty) {
      if (mounted) _showLinkedTransactionsModal(category, transactions);
    } else {
      _confirmDeleteCategory(category);
    }
  }

  void _showLinkedTransactionsModal(Category category, List<TransactionItem> transactions) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 8), Text('Action Required', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]), content: SizedBox(width: double.maxFinite, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Cannot delete "${category.name}" because it has ${transactions.length} transactions assigned.'), const SizedBox(height: 16), const Text('Please reassign these transactions first:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)), const SizedBox(height: 8), Flexible(child: ListView.builder(shrinkWrap: true, itemCount: transactions.length > 5 ? 5 : transactions.length, itemBuilder: (context, index) { final tx = transactions[index]; return ListTile(dense: true, contentPadding: EdgeInsets.zero, title: Text(tx.description, style: const TextStyle(fontSize: 12)), subtitle: Text('${tx.date.split("T")[0]} • €${(tx.amount.value / 100).toStringAsFixed(2)}', style: const TextStyle(fontSize: 10)), trailing: const Icon(Icons.chevron_right, size: 14)); }))])), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('GOT IT'))]));
  }

  void _confirmDeleteCategory(Category category) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text('Delete Category'), content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () async { Navigator.pop(context); try { await _categoryRepo.deleteCategory(category.id); _loadData(silent: true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } }, child: const Text('DELETE', style: TextStyle(color: AppColors.white)))]));
  }

  Widget _buildSubcategoryItem(Subcategory subcategory, int parentId, Color parentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: Row(children: [
        const SizedBox(width: 16),
        Container(width: 6, height: 6, decoration: BoxDecoration(color: parentColor.withValues(alpha: 0.3), shape: BoxShape.circle)),
        const SizedBox(width: 16),
        Expanded(child: Text(subcategory.name, style: AppTextStyles.sidebarItem)),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.black26), onPressed: () => _showCategoryForm(subcategory: subcategory, parentId: parentId)),
        IconButton(icon: Icon(Icons.delete_outline, size: 16, color: Colors.redAccent.withValues(alpha: 0.3)), onPressed: () => _confirmDeleteSubcategory(subcategory)),
      ]),
    );
  }

  void _confirmDeleteSubcategory(Subcategory sub) {
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(title: const Text('Delete Subcategory', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), content: Text('Are you sure you want to delete "${sub.name}"?'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () async { Navigator.pop(context); try { await _categoryRepo.deleteSubcategory(sub.id); _loadData(silent: true); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); } }, child: const Text('DELETE', style: TextStyle(color: AppColors.white)))]));
  }

  Widget _buildAddSubcategoryButton(int parentId, Color statusColor) {
    return Padding(padding: const EdgeInsets.only(left: 48, bottom: 8), child: Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => _showCategoryForm(parentId: parentId), icon: const Icon(Icons.add, size: 14), label: const Text('ADD SUBCATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), style: TextButton.styleFrom(foregroundColor: statusColor.withValues(alpha: 0.6)))));
  }
}
