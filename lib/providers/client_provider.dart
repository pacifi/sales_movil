// lib/providers/client_provider.dart
// Mismo patrón. ClientService.save y .edit ahora reciben token.

import 'package:flutter/material.dart';
import 'package:sales/database/database_helper.dart';
import 'package:sales/models/client.dart';
import 'package:sales/providers/auth_provider.dart';
import 'package:sales/services/client_service.dart';

class ClientProvider extends ChangeNotifier {
  List<Client> _clients = [];
  List<Client> get clients => _clients;

  final DatabaseHelper _db = DatabaseHelper();
  final ClientService _service = ClientService();
  final AuthProvider _authProvider;

  ClientProvider(this._authProvider);

  String get _token => _authProvider.token!;

  Future<void> loadAll() async {
    final rows = await _db.queryAll();
    _clients = rows.map((row) => Client.fromMap(row)).toList();
    notifyListeners();
  }

  Future<void> save(Client client) async {
    await _db.insert(client.toMap());
    await loadAll();
  }

  Future<void> edit(int id, Client client) async {
    await _db.update(id, {
      'name': client.name,
      'document_number': client.documentNumber,
      'is_synced': 0,
      'server_id': client.serverId,
    });
    await loadAll();
  }

  Future<void> delete(Client client) async {
    if (client.isSynced && client.serverId != null) {
      await _service.delete(client.serverId!, _token);
    }
    await _db.delete(client.id);
    await loadAll();
  }

  Future<Map<String, int>> sincronizar() async {
    final rows = await _db.queryPending();
    final pending = rows.map((row) => Client.fromMap(row)).toList();

    int sincronizados = 0;
    int actualizados = 0;
    int duplicados = 0;
    int errores = 0;

    for (final client in pending) {
      if (client.serverId == null) {
        final (result, serverId) = await _service.save(client, _token);
        if (result == SyncResult.created && serverId != null) {
          await _db.updateSynced(client.id, serverId);
          sincronizados++;
        } else if (result == SyncResult.duplicate) {
          duplicados++;
        } else {
          errores++;
        }
      } else {
        final result = await _service.edit(client, _token);
        if (result == SyncResult.updated) {
          await _db.updateSyncedOnly(client.id);
          actualizados++;
        } else {
          errores++;
        }
      }
    }

    await loadAll();
    return {
      'sincronizados': sincronizados,
      'actualizados': actualizados,
      'duplicados': duplicados,
      'errores': errores,
    };
  }
}