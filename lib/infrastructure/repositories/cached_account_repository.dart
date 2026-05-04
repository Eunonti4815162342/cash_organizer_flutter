import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:natave_flutter/domain/models/account_item.dart';
import 'package:natave_flutter/domain/repositories/account_repository.dart';
import 'package:natave_flutter/services/api_service.dart';
import 'package:natave_flutter/service_locator.dart';

class CachedAccountRepository implements IAccountRepository {
  final ApiService _apiService = getIt<ApiService>();
  IAccountRepository? get _localRepo => kIsWeb ? null : getIt<IAccountRepository>(instanceName: 'local_account');

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    if (!kIsWeb) {
      final local = await _localRepo?.fetchAccounts() ?? [];
      if (local.isNotEmpty) {
        _refreshInBackground();
        return local;
      }
    }
    try {
      final remote = await _apiService.fetchAccounts().timeout(const Duration(seconds: 2));
      if (!kIsWeb) await _localRepo?.reconcile(remote);
      return remote;
    } catch (_) { return []; }
  }

  Future<void> _refreshInBackground() async {
    try {
      final remote = await _apiService.fetchAccounts().timeout(const Duration(seconds: 5));
      if (!kIsWeb) await _localRepo?.reconcile(remote);
    } catch (_) {}
  }

  @override
  Future<AccountItem> saveAccount(AccountItem account, {bool isSynced = true}) async {
    if (kIsWeb) {
      final remote = await _apiService.createAccount(account.toJson());
      return remote ?? account;
    }
    final saved = await _localRepo!.saveAccount(account, isSynced: false);
    try {
      final remote = await _apiService.createAccount(account.toJson());
      if (remote != null) await _localRepo?.markAsSynced(saved.id, remote.id);
    } catch (_) {}
    return saved;
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    if (kIsWeb) {
      await _apiService.updateAccount(account.id, account.toJson());
      return;
    }
    await _localRepo!.updateAccount(account, isSynced: false);
    try {
      await _apiService.updateAccount(account.id, account.toJson());
    } catch (_) {}
  }

  @override
  Future<void> saveAll(List<AccountItem> accounts) async {
    if (!kIsWeb) await _localRepo?.saveAll(accounts);
  }

  @override
  Future<AccountItem?> getById(int id) async {
    if (!kIsWeb) return await _localRepo?.getById(id);
    return null;
  }

  @override
  Future<List<AccountItem>> getPendingCreatesToSync() => _localRepo?.getPendingCreatesToSync() ?? Future.value([]);
  @override
  Future<List<AccountItem>> getPendingToSync() => _localRepo?.getPendingToSync() ?? Future.value([]);
  @override
  Future<void> markAsSynced(int localId, int serverId) => _localRepo?.markAsSynced(localId, serverId) ?? Future.value();
}
