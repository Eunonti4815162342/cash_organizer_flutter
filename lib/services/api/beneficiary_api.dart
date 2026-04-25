import '../../domain/models/beneficiary.dart';
import '../../domain/models/transaction_item.dart';
import '../../core/logger/app_logger.dart';
import 'api_client.dart';
import 'package:http/http.dart' as http;

class BeneficiaryApi {
  final ApiClient _client;

  BeneficiaryApi(this._client);

  Future<List<Beneficiary>> fetchAll() async {
    final url = '${_client.baseUrl}/beneficiaries';
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('GET', url, headers);

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    final body = _client.processResponse(response);
    final List<dynamic> list = body['content'] ?? body;
    
    if (list is! List) {
       return [];
    }

    return list.map((json) => Beneficiary.fromJson(json)).toList();
  }

  Future<Map<String, dynamic>?> getTransactionSuggestion(int beneficiaryId) async {
    final url = '${_client.baseUrl}/beneficiaries/$beneficiaryId/suggestion';
    final headers = await _client.authHeaders();
    
    AppLogger.logRequest('GET', url, headers);

    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(Duration(seconds: _client.apiTimeout));
    
    final body = _client.processResponse(response);
    if (body == null) return null;
    
    return body as Map<String, dynamic>;
  }
}
