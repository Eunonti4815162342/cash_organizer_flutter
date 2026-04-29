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
    // 1. LOCAL FIRST
    if (!kIsWeb) {
      final local = await _localRepo?.fetchCategories() ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground();
        return local;
      }
    }

    // 2. NETWORK FALLBACK
    try {
      final remote = await _apiService.fetchCategories();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
      return remote;
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchCategories();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
    } catch (_) {}
  }

  @override
  Future<Category?> getById(int id) async {
    if (kIsWeb) return null;
    return await _localRepo?.getById(id);
  }

  @override
  Future<void> saveAll(List<Category> categories) async {
    if (!kIsWeb) await _localRepo?.saveAll(categories);
  }

  @override
  Future<void> saveCategory(Category category) async {
    if (!kIsWeb) await _localRepo?.saveCategory(category);
  }

  @override
  Future<void> deleteCategory(int id) async {
    // 1. Delete on Server
    await _apiService.deleteCategory(id);
    
    // 2. Delete on Local
    if (!kIsWeb) {
      await _localRepo?.deleteCategory(id);
    }
  }

  @override
  Future<void> deleteSubcategory(int id) async {
    // 1. Delete on Server
    await _apiService.deleteSubcategory(id);
    
    // 2. Delete on Local
    if (!kIsWeb) {
      await _localRepo?.deleteSubcategory(id);
    }
  }
}
