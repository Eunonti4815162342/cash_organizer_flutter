import '../../domain/models/account_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../../services/api_service.dart';
import 'sqlite/sqlite_account_repository.dart';

class CachedAccountRepository implements IAccountRepository {
  final ApiService _apiService = ApiService();
  final SqliteAccountRepository _localRepo = SqliteAccountRepository();

  @override
  Future<List<AccountItem>> fetchAccounts() async {
    try {
      // 1. Intentar obtener de la API
      final remoteAccounts = await _apiService.fetchAccounts();
      
      if (remoteAccounts.isNotEmpty) {
        // 2. Si hay éxito, actualizar caché local
        await _localRepo.saveAll([remoteAccounts]);
        return remoteAccounts;
      }
    } catch (e) {
      print('[CachedAccountRepository] Error fetching remote, falling back to local: $e');
    }

    // 3. Si falla o no hay red, devolver lo que tengamos en SQLite
    return await _localRepo.fetchAccounts();
  }

  @override
  Future<void> saveAccount(AccountItem account) async {
    // Primero en local para feedback instantáneo
    await _localRepo.saveAccount(account);
    // Luego intentamos subirlo (en una tarea real, aquí iría la lógica de Sync)
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
    await _localRepo.saveAll([accounts]);
  }

  @override
  Future<AccountItem?> getById(int id) async {
    return await _localRepo.getById(id);
  }
}
