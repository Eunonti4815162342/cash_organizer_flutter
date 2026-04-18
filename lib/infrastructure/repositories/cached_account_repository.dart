import '../../domain/models/account_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../../services/api_service.dart';
import 'sqlite/sqlite_account_repository.dart';
import '../../service_locator.dart';

class CachedAccountRepository implements IAccountRepository {
  final ApiService _apiService = getIt<ApiService>();
  final SqliteAccountRepository _localRepo = SqliteAccountRepository();

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final remoteAccounts = await _apiService.fetchAccounts();
      if (remoteAccounts.isNotEmpty) {
        await _localRepo.saveAll(remoteAccounts);
        return remoteAccounts;
      }
    } catch (e) {
      print('[CachedAccountRepository] Error fetching remote, falling back to local: $e');
    }
    return await _localRepo.fetchAccounts();
  }

  @override
  Future<void> saveAccount(AccountItem account) async {
    await _localRepo.saveAccount(account);
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
    await _localRepo.saveAll(accounts);
  }

  @override
  Future<AccountItem?> getById(int id) async {
    return await _localRepo.getById(id);
  }
}
