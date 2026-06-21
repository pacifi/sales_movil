// lib/services/client_service.dart
// Mismo patrón — token como parámetro. SyncResult se mantiene igual.

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:sales/config/app_config.dart';
import 'package:sales/models/client.dart';

enum SyncResult { created, updated, duplicate, error }

class ClientService {
  final String apiUrl = AppConfig.apiUrl;

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<(SyncResult, int?)> save(Client client, String token) async {
    var url = Uri.http(apiUrl, '/client/clients/');
    var response = await http.post(
      url,
      body: convert.jsonEncode(client.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode == 201) {
      final json = convert.jsonDecode(response.body);
      return (SyncResult.created, json['id'] as int);
    }
    if (response.statusCode == 400) return (SyncResult.duplicate, null);
    return (SyncResult.error, null);
  }

  Future<SyncResult> edit(Client client, String token) async {
    var url = Uri.http(apiUrl, '/client/clients/${client.serverId}/');
    var response = await http.put(
      url,
      body: convert.jsonEncode(client.toJson()),
      headers: _headers(token),
    );
    if (response.statusCode == 200) return SyncResult.updated;
    return SyncResult.error;
  }

  Future<void> delete(int serverId, String token) async {
    var url = Uri.http(apiUrl, '/client/clients/$serverId/');
    var response = await http.delete(url, headers: _headers(token));
    if (response.statusCode != 204) {
      throw Exception('Error al eliminar cliente');
    }
  }
}