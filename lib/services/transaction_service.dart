import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/transaction_item.dart';
import 'http_client_manager.dart';

class TransactionService {
  final HttpClientManager _clientManager;

  TransactionService(this._clientManager);

  Future<List<TransactionItem>> fetchTransactions({String? startDate, String? endDate, String? accountId}) async {
    try {
      String url = '${_clientManager.baseUrl}/transactions?';
      if (startDate != null) url += 'startDate=$startDate&';
      if (endDate != null) url += 'endDate=$endDate&';
      if (accountId != null) url += 'accountId=$accountId&';

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> jsonList = body['content'] ?? [];
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw 'SESSION_EXPIRED';
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions';
      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions/$id';
      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(transactionData),
      );

      if (response.statusCode == 200) {
        return TransactionItem.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
