import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';
import '../services/sync_service.dart';

class OrderRepository {
  final SupabaseService _supabase;
  final LocalDbService _localDb;
  final SyncService _syncService;

  OrderRepository(this._supabase, this._localDb, this._syncService);

  Future<String> crearPedido(OrderModel pedido, List<OrderItemModel> items) async {
    if (await _syncService.hayConexion()) {
      try {
        final pedidoId = await _supabase.crearPedido(pedido);
        final itemsConId = items
            .map((i) => OrderItemModel(
                  productoId: i.productoId,
                  cantidad: i.cantidad,
                  precioUnitario: i.precioUnitario,
                  subtotal: i.subtotal,
                  pedidoId: pedidoId,
                ))
            .toList();
        await _supabase.agregarDetalle(itemsConId);
        return pedidoId;
      } catch (e) {
        debugPrint('Error al crear pedido en Supabase (fallback offline): $e');
      }
    }

    final pedidoConItems = pedido.copyWith(items: items);
    final localId = await _localDb.crearPedidoLocal(pedidoConItems);
    await _localDb.agregarDetalleLocal(
        items.map((i) => i.copyWith(pedidoId: localId)).toList());
    await _syncService.sincronizarPedidosPendientes();
    return localId;
  }

  Future<List<OrderModel>> obtenerPedidos(String userId) async {
    if (await _syncService.hayConexion()) {
      try {
        return await _supabase.obtenerPedidos(userId);
      } catch (e) {
        debugPrint('Error al obtener pedidos de Supabase: $e');
      }
    }
    return _localDb.obtenerTodosPedidosLocales();
  }

  Future<OrderModel?> obtenerPedido(String id) async {
    if (await _syncService.hayConexion()) {
      try {
        final pedido = await _supabase.obtenerPedido(id);
        if (pedido != null) return pedido;
      } catch (e) {
        debugPrint('Error al obtener pedido $id de Supabase: $e');
      }
    }
    return _localDb.obtenerPedidoLocal(id);
  }

  Future<void> confirmarPedido(String pedidoId, String firmaBase64) async {
    if (await _syncService.hayConexion()) {
      await _supabase.subirFirma(pedidoId, firmaBase64);
    }
    await _localDb.marcarSincronizado(pedidoId);
  }

  Future<void> agregarFirmaAPedido(String pedidoId, String firmaBase64) async {
    if (await _syncService.hayConexion()) {
      await _supabase.agregarFirma(pedidoId, firmaBase64);
    }
    await _localDb.actualizarFirmaLocal(pedidoId, firmaBase64);
  }

  Future<void> confirmarPedidoExistente(String pedidoId) async {
    if (await _syncService.hayConexion()) {
      await _supabase.actualizarEstadoPedido(pedidoId, 'CONFIRMADO');
    }
    await _localDb.actualizarEstadoPedidoLocal(pedidoId, 'CONFIRMADO');
  }
}

extension _OrderModelCopy on OrderModel {
  OrderModel copyWith({List<OrderItemModel>? items}) {
    return OrderModel(
      id: id,
      vendedorId: vendedorId,
      clienteId: clienteId,
      fecha: fecha,
      estado: estado,
      total: total,
      firma: firma,
      notas: notas,
      latitud: latitud,
      longitud: longitud,
      items: items ?? this.items,
    );
  }
}

extension _OrderItemCopy on OrderItemModel {
  OrderItemModel copyWith({String? pedidoId}) {
    return OrderItemModel(
      id: id,
      pedidoId: pedidoId ?? this.pedidoId,
      productoId: productoId,
      cantidad: cantidad,
      precioUnitario: precioUnitario,
      subtotal: subtotal,
      producto: producto,
    );
  }
}
