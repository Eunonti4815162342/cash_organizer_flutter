import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/account_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedAccountRepository implements IAccountRepository {
  final ApiService _apiService = getIt<ApiService>();

  IAccountRepository? get _localRepo =>
      kIsWeb ? null : getIt<IAccountRepository>(instanceName: 'local_account');

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final remote = await _apiService.fetchAccounts();
      if (remote.isNotEmpty && !kIsWeb) {
        await _localRepo?.saveAll(remote);
      }
      return remote;
    } catch (e) {
      if (kIsWeb) return [];
      return await _localRepo?.fetchAccounts() ?? [];
    }
  }

  @override
  Future<void> saveAccount(AccountItem account, {bool isSynced = true}) async {
    try {
      final result = await _apiService.createAccount(_buildPayload(account));
      if (result != null && !kIsWeb) {
        await _localRepo?.saveAccount(result, isSynced: true);
      }
    } catch (e) {
      // Crear cuenta requiere conexión — no guardamos pendiente sin server ID
      rethrow;
    }
  }

  @override
  Future<void> updateAccount(AccountItem account, {bool isSynced = true}) async {
    try {
      final result = await _apiService.updateAccount(account.id, _buildPayload(account));
      if (result != null && !kIsWeb) {
        await _localRepo?.saveAll([result]);
      }
    } catch (e) {
      if (!kIsWeb) {
        await _localRepo?.updateAccount(account, isSynced: false);
      }
    }
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
  Future<List<AccountItem>> getPendingToSync() async {
    if (kIsWeb) return [];
    return await _localRepo?.getPendingToSync() ?? [];
  }

  @override
  Future<void> markAsSynced(int localId, int serverId) async {
    if (!kIsWeb) await _localRepo?.markAsSynced(localId, serverId);
  }

  Map<String, dynamic> _buildPayload(AccountItem account) => {
    'name': account.name,
    'description': account.description,
    'amount': {
      'value': account.amount.value,
      'currency': account.amount.currency,
      'isNegative': account.amount.isNegative,
    },
    'accountType': account.accountType ?? 'CASH',
    'active': true,
  };
}
