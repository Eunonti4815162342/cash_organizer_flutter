import '../../domain/models/beneficiary.dart';

abstract class IBeneficiaryRepository {
  Future<List<Beneficiary>> getAllBeneficiaries();
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId);
}
