import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/core/logger/app_logger.dart';
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
      final remote = await _apiService.fetchCategories();
      if (!kIsWeb) await _localRepo?.reconcile(remote);
      return remote;
    } catch (_) { return []; }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchCategories();
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
    if (category.id > 0) {
      // Update: save locally first for immediate feedback, then sync to API.
      if (!kIsWeb) await _localRepo?.saveCategory(category);
      try {
        await _apiService.updateCategory(category.id, category);
      } catch (e, st) {
        AppLogger.error('saveCategory update API error', e, st);
      }
    } else {
      // Create: API first so we get the server-assigned id; then save locally
      // with that id. Saving locally with id 0 first (then again with the
      // real id) left a permanent duplicate row behind, since nothing ever
      // removed the id-0 entry.
      try {
        final created = await _apiService.createCategory(category);
        if (!kIsWeb && created != null) await _localRepo?.saveCategory(created);
      } catch (e, st) {
        AppLogger.error('saveCategory create API error', e, st);
        if (!kIsWeb) await _localRepo?.saveCategory(category);
      }
    }
  }

  @override
  Future<void> saveSubcategory(int categoryId, Subcategory sub) async {
    if (sub.id > 0) {
      // Update: save locally first for immediate feedback, then sync to API.
      if (!kIsWeb) await _localRepo?.saveSubcategory(categoryId, sub);
      try {
        await _apiService.updateSubcategory(sub.id, sub);
      } catch (e, st) {
        AppLogger.error('saveSubcategory update API error', e, st);
      }
    } else {
      // Create: API first so we get the server-assigned id; then save locally
      // with that id. This prevents reconcile from deleting the orphan local id.
      try {
        final created = await _apiService.createSubcategory(categoryId, sub);
        if (!kIsWeb && created != null) {
          await _localRepo?.saveSubcategory(categoryId, created);
        }
      } catch (e, st) {
        AppLogger.error('saveSubcategory create API error', e, st);
        // API failed: save locally as fallback so the user sees the entry;
        // the next background sync will either reconcile or remove it.
        if (!kIsWeb) await _localRepo?.saveSubcategory(categoryId, sub);
      }
    }
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
