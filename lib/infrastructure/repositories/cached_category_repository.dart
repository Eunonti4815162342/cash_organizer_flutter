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
      if (remote.isNotEmpty && !kIsWeb) await _localRepo?.saveAll(remote);
      return remote;
    } catch (e) { return []; }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchCategories().timeout(const Duration(seconds: 5));
      if (remote.isNotEmpty && !kIsWeb) await _localRepo?.saveAll(remote);
    } catch (_) {}
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
    _apiService.createCategory(category).catchError((_) => null);
  }

  @override
  Future<void> saveSubcategory(int categoryId, Subcategory sub) async {
    if (!kIsWeb) await _localRepo?.saveSubcategory(categoryId, sub);
    if (sub.id > 0) {
      _apiService.updateSubcategory(sub.id, sub).catchError((_) => null);
    } else {
      _apiService.createSubcategory(categoryId, sub).catchError((_) => null);
    }
  }

  @override
  Future<void> deleteCategory(int id) async {
    if (!kIsWeb) await _localRepo?.deleteCategory(id);
    _apiService.deleteCategory(id).catchError((_) => null);
  }

  @override
  Future<void> deleteSubcategory(int id) async {
    if (!kIsWeb) await _localRepo?.deleteSubcategory(id);
    _apiService.deleteSubcategory(id).catchError((_) => null);
  }
}
