import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/category.dart';
import 'package:natave_flutter/domain/repositories/category_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

class CachedCategoryRepository implements ICategoryRepository {
  final ApiService _apiService = getIt<ApiService>();
  ICategoryRepository? get _localRepo => kIsWeb ? null : getIt<ICategoryRepository>(instanceName: 'local_category');

  @override
  Future<List<Category>> fetchCategories() async {
    if (!kIsWeb) {
      final local = await _localRepo?.fetchCategories() ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground();
        return local;
      }
    }
    try {
      final remote = await _apiService.fetchCategories().timeout(const Duration(seconds: 2));
      if (!kIsWeb) await _localRepo?.reconcile(remote);
      return remote;
    } catch (_) { return []; }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchCategories().timeout(const Duration(seconds: 5));
      if (!kIsWeb) await _localRepo?.reconcile(remote);
    } catch (_) {}
  }

  @override
  Future<void> reconcile(List<Category> serverCategories) async {
    if (!kIsWeb) await _localRepo?.reconcile(serverCategories);
  }

  @override
  Future<Category?> getById(int id) async {
    if (!kIsWeb) return await _localRepo?.getById(id);
    return null;
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    if (!kIsWeb) await _localRepo?.saveAll(categories);
  }

  @override
  Future<void> saveCategory(Category category) async {
    if (!kIsWeb) await _localRepo?.saveCategory(category);
    if (!kIsWeb) {
      try {
        await _apiService.createCategory(category);
      } catch (_) {}
    }
  }

  @override
  Future<void> saveSubcategory(int categoryId, Subcategory sub) async {
    if (!kIsWeb) await _localRepo?.saveSubcategory(categoryId, sub);
    try {
      if (sub.id > 0) {
        await _apiService.updateSubcategory(sub.id, sub);
      } else {
        await _apiService.createSubcategory(categoryId, sub);
      }
    } catch (_) {}
  }

  @override
  Future<void> deleteCategory(int id) async {
    if (!kIsWeb) await _localRepo?.deleteCategory(id);
    try {
      await _apiService.deleteCategory(id);
    } catch (_) {}
  }

  @override
  Future<void> deleteSubcategory(int id) async {
    if (!kIsWeb) await _localRepo?.deleteSubcategory(id);
    try {
      await _apiService.deleteSubcategory(id);
    } catch (_) {}
  }
}
