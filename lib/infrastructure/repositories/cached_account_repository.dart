import 'package:flutter/foundation.dart' show kIsWeb;
import '../../domain/models/account_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../../services/api_service.dart';
import '../../service_locator.dart';

class CachedAccountRepository implements IAccountRepository {
  final ApiService _apiService = getIt<ApiService>();
  
  // Usamos dynamic o un acceso seguro para evitar cargar el tipo Sqlite en Web
  IAccountRepository? get _localRepo => kIsWeb ? null : getIt<IAccountRepository>(instanceName: 'local_account');

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final remoteAccounts = await _apiService.fetchAccounts();
      if (remoteAccounts.isNotEmpty) {
        if (!kIsWeb) {
          await _localRepo?.saveAll(remoteAccounts);
        }
        return remoteAccounts;
      }
    } catch (e) {
      print('[CachedAccountRepository] Error: $e');
      if (kIsWeb) return [];
    }
    return kIsWeb ? [] : (await _localRepo?.fetchAccounts() ?? []);
  }

  @override
  Future<void> saveAccount(AccountItem account) async {
    if (!kIsWeb) {
      await _localRepo?.saveAccount(account);
    }
    await _apiService.createAccount({
      'name': account.name,
      'amount': {
        'value': account.amount.value,
        'currency': account.amount.currency,
      },
      'description': account.description,
    });
  }

  @override
  Future<void> saveAll(List<AccountItem> accounts) async {
    if (!kIsWeb) {
      await _localRepo?.saveAll(accounts);
    }
  }

  @override
  Future<AccountItem?> getById(int id) async {
    if (kIsWeb) return null;
    return await _localRepo?.getById(id);
  }
}
