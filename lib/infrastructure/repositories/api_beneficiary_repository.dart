import '../../domain/models/beneficiary.dart';
import '../../domain/repositories/beneficiary_repository.dart';
import '../../services/api_service.dart';

class ApiBeneficiaryRepository implements IBeneficiaryRepository {
  final ApiService _apiService;

  ApiBeneficiaryRepository(this._apiService);

  @override
  Future<List<Beneficiary>> getAllBeneficiaries() async {
    final response = await _apiService.fetchBeneficiaries();
    return response.map((json) => Beneficiary.fromJson(json)).toList();
  }

  @override
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    return await _apiService.getTransactionSuggestion(beneficiaryId);
  }
}
