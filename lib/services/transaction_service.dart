import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/transaction_item.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/error/error_handler.dart';
import '../core/logger/app_logger.dart';
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

      AppLogger.logRequest('GET', url, await _clientManager.getHeaders());

      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> jsonList = body['content'] ?? [];
        AppLogger.logResponse(response.statusCode, url, 'Fetched ${jsonList.length} transactions');
        return jsonList.map((json) => TransactionItem.fromJson(json)).toList();
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException rethrow {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      rethrow;
    }
  }

  Future<TransactionItem?> createTransaction(Map<String, dynamic> transactionData) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions';
      AppLogger.logRequest('POST', url, await _clientManager.getHeaders());

      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(transactionData),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = TransactionItem.fromJson(jsonDecode(response.body));
        AppLogger.info('Transaction created successfully');
        return result;
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException rethrow {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      rethrow;
    }
  }

  Future<TransactionItem?> updateTransaction(int id, Map<String, dynamic> transactionData) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions/$id';
      AppLogger.logRequest('PUT', url, await _clientManager.getHeaders());

      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(transactionData),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      if (response.statusCode == 200) {
        final result = TransactionItem.fromJson(jsonDecode(response.body));
        AppLogger.info('Transaction $id updated successfully');
        return result;
      } else {
        throw ErrorHandler.handleHttpError(response);
      }
    } on AppException rethrow {
      rethrow;
    } catch (e, stackTrace) {
      final exception = ErrorHandler.handleException(e, stackTrace);
      AppLogger.logException(exception);
      rethrow;
    }
  }

  Future<bool> deleteTransaction(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/transactions/$id';
      AppLogger.logRequest('DELETE', url, await _clientManager.getHeaders());

      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      ).timeout(Duration(seconds: _clientManager.apiTimeout));

      final success = response.statusCode == 200 || response.statusCode == 204;
      if (success) {
        AppLogger.info('Transaction $id deleted successfully');
      }
      return success;
    } catch (e, stackTrace) {
      AppLogger.error('Delete transaction error', e, stackTrace);
      return false;
    }
  }
}
