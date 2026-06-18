import 'package:flutter/foundation.dart';
import '../models/client.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

class ClientRepository {
  final SupabaseService _supabase;
  final LocalDbService _localDb;
  final SyncService _syncService;

  ClientRepository(this._supabase, this._localDb, this._syncService);

  Future<List<ClientModel>> obtenerClientes(String userId) async {
    try {
      final clientes = await _supabase.obtenerClientes(userId);
      await _localDb.guardarClientes(clientes);
      return clientes;
    } catch (e) {
      debugPrint('Error al obtener clientes de Supabase: $e');
    }
    return _localDb.obtenerClientes();
  }

  Future<ClientModel?> obtenerCliente(int id) async {
    try {
      final cliente = await _supabase.obtenerCliente(id);
      if (cliente != null) return cliente;
    } catch (e) {
      debugPrint('Error al obtener cliente $id de Supabase: $e');
    }
    return _localDb.obtenerCliente(id);
  }
}
