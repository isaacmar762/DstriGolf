import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/price.dart';
import '../models/order.dart';
import '../models/order_item.dart';

class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  SupabaseClient get client => _client;

  Future<AuthResponse> signUp(String email, String password) async {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  User? get currentUser => _client.auth.currentUser;

  Future<void> crearPerfil(UserModel perfil) async {
    await _client.from('perfiles').insert(perfil.toMap());
  }

  Future<UserModel?> obtenerPerfil(String userId) async {
    try {
      final res = await _client
          .from('perfiles')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  Future<List<ClientModel>> obtenerClientes(String userId) async {
    final res = await _client.rpc('obtener_clientes_vendedor', params: {
      'p_vendedor_id': userId,
    });
    return (res as List).map((e) => ClientModel.fromMap(e)).toList();
  }

  Future<ClientModel?> obtenerCliente(int id) async {
    try {
      final res = await _client
          .from('clientes')
          .select('*, zonas!inner(nombre)')
          .eq('id', id)
          .single();
      final data = res as Map<String, dynamic>;
      data['zona_nombre'] = data['zonas']?['nombre'];
      return ClientModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> obtenerProductos({String? linea}) async {
    try {
      dynamic query = _client.from('productos').select('*').isFilter('activo', true);
      if (linea != null) {
        query = query.eq('nombre_linea', linea);
      }
      final res = await query.order('id', ascending: true);
      final list = res as List;
      return list.map((e) => ProductModel.fromMap(e as Map<String, dynamic>)).toList();
    } catch (e) {
      print('obtenerProductos error: $e');
      rethrow;
    }
  }

  Future<List<String>> obtenerLineas() async {
    final res = await _client
        .from('productos')
        .select('nombre_linea')
        .eq('activo', true)
        .order('nombre_linea');
    final lineas = (res as List)
        .map((e) => e['nombre_linea'] as String?)
        .where((e) => e != null && e.isNotEmpty)
        .map((e) => e!)
        .toSet()
        .toList();
    return lineas;
  }

  Future<PriceModel?> obtenerPrecio(int productoId, String tipoVendedor) async {
    try {
      final table = tipoVendedor == 'MAYORISTA' ? 'precios_mayorista' : 'precios_tat';
      final res = await _client
          .from(table)
          .select()
          .eq('producto_id', productoId)
          .maybeSingle();
      if (res == null) return null;
      return PriceModel.fromMap(res);
    } catch (_) {
      return null;
    }
  }

  Future<void> crearProducto(Map<String, dynamic> data) async {
    await _client.from('productos').insert(data);
  }

  Future<void> actualizarProducto(int id, Map<String, dynamic> data) async {
    await _client.from('productos').update(data).eq('id', id);
  }

  Future<void> eliminarProducto(int id) async {
    await _client.from('productos').update({'activo': false}).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> obtenerProductosConPrecio(
      String tipoVendedor) async {
    final table = tipoVendedor == 'MAYORISTA' ? 'precios_mayorista' : 'precios_tat';
    final res = await _client
        .from(table)
        .select('*, productos!inner(*)')
        .order('productos(nombre)');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<String> crearPedido(OrderModel pedido) async {
    final res = await _client.from('pedidos').insert(pedido.toMap()).select('id').single();
    return res['id'] as String;
  }

  Future<void> agregarDetalle(List<OrderItemModel> items) async {
    await _client.from('detalle_pedido').insert(
      items.map((e) => e.toMap()).toList(),
    );
  }

  Future<void> actualizarPedido(OrderModel pedido) async {
    await _client.from('pedidos').update(pedido.toMap()).eq('id', pedido.id!);
  }

  Future<void> crearCliente(Map<String, dynamic> data) async {
    await _client.from('clientes').insert(data);
  }

  Future<void> actualizarCliente(int id, Map<String, dynamic> data) async {
    await _client.from('clientes').update(data).eq('id', id);
  }

  Future<List<Map<String, dynamic>>> obtenerZonas() async {
    final res = await _client.from('zonas').select().order('nombre');
    return (res as List).cast<Map<String, dynamic>>();
  }

  Future<void> crearZona(String nombre) async {
    await _client.from('zonas').insert({'nombre': nombre});
  }

  Future<String> uploadImagen(String bucket, String path, Uint8List bytes) async {
    await _client.storage.from(bucket).uploadBinary(path, bytes);
    final url = _client.storage.from(bucket).getPublicUrl(path);
    return url;
  }

  Future<List<OrderModel>> obtenerPedidos(String userId) async {
    final res = await _client
        .from('pedidos')
        .select('*, clientes!inner(*)')
        .eq('vendedor_id', userId)
        .order('fecha', ascending: false);
    return (res as List).map((e) {
      final data = e as Map<String, dynamic>;
      data['cliente'] = data['clientes'];
      return OrderModel.fromMap(data);
    }).toList();
  }

  Future<OrderModel?> obtenerPedido(String id) async {
    try {
      final res = await _client
          .from('pedidos')
          .select('*, clientes!inner(*), detalle_pedido(*, productos!inner(*))')
          .eq('id', id)
          .maybeSingle();
      if (res == null) return null;
      final data = res as Map<String, dynamic>;
      data['cliente'] = data['clientes'];
      data['items'] = data['detalle_pedido'];
      return OrderModel.fromMap(data);
    } catch (_) {
      return null;
    }
  }

  Future<void> subirFirma(String pedidoId, String firmaBase64) async {
    await _client
        .from('pedidos')
        .update({'firma': firmaBase64, 'estado': 'CONFIRMADO'})
        .eq('id', pedidoId);
  }

  Future<void> agregarFirma(String pedidoId, String firmaBase64) async {
    await _client
        .from('pedidos')
        .update({'firma': firmaBase64})
        .eq('id', pedidoId);
  }

  Future<void> actualizarEstadoPedido(String pedidoId, String estado) async {
    await _client
        .from('pedidos')
        .update({'estado': estado})
        .eq('id', pedidoId);
  }

  Future<List<UserModel>> obtenerVendedores() async {
    final res = await _client
        .from('perfiles')
        .select()
        .neq('tipo_vendedor', 'ADMIN')
        .order('nombre');
    return (res as List).map((e) => UserModel.fromMap(e)).toList();
  }

  Future<void> activarVendedor(String userId, bool activo) async {
    await _client
        .from('perfiles')
        .update({'activo': activo})
        .eq('id', userId);
  }

  Future<void> asignarZona(String vendedorId, int zonaId) async {
    await _client.from('vendedor_zonas').insert({
      'vendedor_id': vendedorId,
      'zona_id': zonaId,
    });
  }

  Future<void> asignarCliente(String vendedorId, int clienteId) async {
    await _client.from('vendedor_clientes').insert({
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
    });
  }

  Future<List<Map<String, dynamic>>> obtenerReporteVentas(
      {DateTime? desde, DateTime? hasta}) async {
    final res = await _client.rpc('obtener_reporte_ventas', params: {
      if (desde != null) 'p_desde': desde.toIso8601String(),
      if (hasta != null) 'p_hasta': hasta.toIso8601String(),
    });
    return (res as List).cast<Map<String, dynamic>>();
  }
}
