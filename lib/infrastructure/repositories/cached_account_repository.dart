import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/account_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

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
      final remote = await _apiService.fetchAccounts();
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
      final remote = await _apiService.fetchAccounts();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
    } catch (_) {}
  }

  @override
  Future<AccountItem> saveAccount(AccountItem account, {bool isSynced = true}) async {
    if (kIsWeb) return await _apiService.createAccount(account.toJson()) ?? account;
    
    final saved = await _localRepo!.saveAccount(account, isSynced: false);
    _apiService.createAccount(account.toJson()).then((remote) {
      if (remote != null) _localRepo?.markAsSynced(saved.id, remote.id);
    }).catchError((_) {
      return null;
    });

    return saved;
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    if (kIsWeb) {
      await _apiService.updateAccount(account.id, account.toJson());
      return;
    }
    await _localRepo!.updateAccount(account, isSynced: false);
    _apiService.updateAccount(account.id, account.toJson()).catchError((_) {
      return null;
    });
  }

  @override
  Future<void> saveAll(List<AccountItem> accounts) async {
    if (!kIsWeb) await _localRepo?.saveAll(accounts);
  }

  @override
  Future<AccountItem?> getById(int id) async {
    if (kIsWeb) return null;
    return await _localRepo?.getById(id);
  }

  @override
  Future<List<AccountItem>> getPendingCreatesToSync() => _localRepo?.getPendingCreatesToSync() ?? Future.value([]);
  @override
  Future<List<AccountItem>> getPendingToSync() => _localRepo?.getPendingToSync() ?? Future.value([]);
  @override
  Future<void> markAsSynced(int localId, int serverId) => _localRepo?.markAsSynced(localId, serverId) ?? Future.value();
}
