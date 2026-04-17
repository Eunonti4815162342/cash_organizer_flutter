import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/account_item.dart';
import 'http_client_manager.dart';

class AccountService {
  final HttpClientManager _clientManager;

  AccountService(this._clientManager);

  Future<List<AccountItem>> fetchAccounts() async {
    try {
      final url = '${_clientManager.baseUrl}/accounts';
      final response = await http.get(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List<dynamic> jsonList = body is List ? body : (body['content'] ?? []);
        return jsonList.map((json) => AccountItem.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw 'SESSION_EXPIRED';
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AccountItem?> createAccount(Map<String, dynamic> accountData) async {
    try {
      final url = '${_clientManager.baseUrl}/accounts';
      final response = await http.post(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(accountData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AccountItem.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<AccountItem?> updateAccount(int id, Map<String, dynamic> accountData) async {
    try {
      final url = '${_clientManager.baseUrl}/accounts/$id';
      final response = await http.put(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
        body: jsonEncode(accountData),
      );

      if (response.statusCode == 200) {
        return AccountItem.fromJson(jsonDecode(response.body));
      } else {
        throw 'Error ${response.statusCode}: ${response.body}';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deleteAccount(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/accounts/$id';
      final response = await http.delete(
        Uri.parse(url),
        headers: await _clientManager.getHeaders(),
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccountPermanently(int id) async {
    try {
      final url = '${_clientManager.baseUrl}/accounts/$id/permanent';
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
