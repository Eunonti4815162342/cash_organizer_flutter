import '../../domain/models/beneficiary.dart';
import '../../domain/repositories/beneficiary_repository.dart';
import '../../services/api_service.dart';

class ApiBeneficiaryRepository implements IBeneficiaryRepository {
  final ApiService _apiService;

  ApiBeneficiaryRepository(this._apiService);

  @override
  Future<List<Beneficiary>> getAllBeneficiaries() async {
    final response = await _apiService.fetchBeneficiaries();
    return response;
  }

  @override
  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    final suggestion = await _apiService.getTransactionSuggestion(beneficiaryId);
    // El ApiService ya devuelve Map<String, dynamic> a través del pipeline
    // pero necesitamos asegurar la consistencia del tipo de retorno
    if (suggestion == null) return null;
    return suggestion as Map<String, dynamic>;
  }

  @override
  Future<void> updateBeneficiaryMemory(int id, int? catId, int? subId, String? type) async {
    // Por ahora, el API no soporta actualización de memoria de beneficiario individualmente.
  }
}
