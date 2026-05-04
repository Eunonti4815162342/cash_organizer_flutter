import '../models/account_item.dart';

abstract class IAccountRepository {
  Future<List<AccountItem>> fetchAccounts();
  Future<AccountItem> saveAccount(AccountItem account, {bool isSynced = true});
  Future<void> updateAccount(AccountItem account, {bool isSynced = true});
  Future<void> saveAll(List<AccountItem> accounts);
  Future<void> reconcile(List<AccountItem> serverAccounts);
  Future<AccountItem?> getById(int id);
  Future<List<AccountItem>> getPendingCreatesToSync();
  Future<List<AccountItem>> getPendingToSync();
  Future<void> markAsSynced(int localId, int serverId);
}
