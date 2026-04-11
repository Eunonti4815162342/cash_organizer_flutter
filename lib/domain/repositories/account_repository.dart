import '../models/account_item.dart';

abstract class IAccountRepository {
  Future<List<AccountItem>> fetchAccounts();
  Future<void> saveAccount(AccountItem account);
  Future<void> saveAll(List<AccountItem> accounts);
  Future<AccountItem?> getById(int id);
}
