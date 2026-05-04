import '../../domain/models/beneficiary.dart';

abstract class IBeneficiaryRepository {
  Future<List<Beneficiary>> getAllBeneficiaries();
  Future<void> reconcile(List<Beneficiary> serverBeneficiaries);
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId);
  Future<void> updateBeneficiaryMemory(int id, int? catId, int? subId, String? type);
}
