import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../models/price.dart';
import '../models/sync_log.dart';
import 'supabase_service.dart';
import 'local_db_service.dart';

class SyncService {
  final SupabaseService _supabase;
  final LocalDbService _localDb;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription? _subscription;

  bool _syncing = false;

  SyncService(this._supabase, this._localDb);

  void iniciarSyncAutomatico() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi) {
        sincronizarPedidosPendientes();
      }
    });
  }

  void detenerSyncAutomatico() {
    _subscription?.cancel();
  }

  Future<bool> hayConexion() async {
    final result = await _connectivity.checkConnectivity();
    return result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi;
  }

  Future<void> sincronizarPedidosPendientes() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final pendientes = await _localDb.obtenerPedidosPendientes();

      for (final pedido in pendientes) {
        await _sincronizarPedido(pedido);
      }
    } finally {
      _syncing = false;
    }
  }

  Future<void> _sincronizarPedido(OrderModel pedido) async {
    try {
      final pedidoId = await _supabase.crearPedido(pedido);

      if (pedido.items != null && pedido.items!.isNotEmpty) {
        final items = pedido.items!
            .map((item) => OrderItemModel(
                  productoId: item.productoId,
                  cantidad: item.cantidad,
                  precioUnitario: item.precioUnitario,
                  subtotal: item.subtotal,
                  pedidoId: pedidoId,
                ))
            .toList();
        await _supabase.agregarDetalle(items);
      }

      await _localDb.marcarSincronizado(pedido.id!);
      await _localDb.registrarSync(SyncLog(
        pedidoId: pedido.id!,
        accion: 'CREAR',
        estado: 'EXITO',
      ));
    } catch (e) {
      await _localDb.registrarSync(SyncLog(
        pedidoId: pedido.id!,
        accion: 'CREAR',
        estado: 'ERROR: $e',
      ));
    }
  }

  Future<void> sincronizarCatalogo(String userId, String tipoVendedor) async {
    if (!await hayConexion()) return;

    try {
      final clientes = await _supabase.obtenerClientes(userId);
      await _localDb.guardarClientes(clientes);

      final productos = await _supabase.obtenerProductos();
      await _localDb.guardarProductos(productos);

      final preciosData = await _supabase.obtenerProductosConPrecio(tipoVendedor);

      final preciosModels = <PriceModel>[];
      for (final p in preciosData) {
        preciosModels.add(PriceModel.fromMap({
          ...p,
          'producto_id': p['producto_id'],
          'bruto': (p['bruto'] as num?)?.toDouble() ?? 0,
          'unitario': (p['unitario'] as num?)?.toDouble() ?? 0,
          'max_descuento': (p['max_descuento'] as num?)?.toDouble() ?? 0,
          'minimo': (p['minimo'] as num?)?.toDouble() ?? 0,
          'impuestos': (p['impuestos'] as num?)?.toDouble() ?? 0,
        }));
      }

      final uniquePrecios = <int, PriceModel>{};
      for (final pm in preciosModels) {
        uniquePrecios[pm.productoId] = pm;
      }
      await _localDb.guardarPrecios(uniquePrecios.values.toList(), tipoVendedor);
    } catch (e) {
      debugPrint('Error al sincronizar catálogo: $e');
    }
  }
}
