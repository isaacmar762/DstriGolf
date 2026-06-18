import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/price.dart';
import '../services/supabase_service.dart';
import '../services/local_db_service.dart';

class ProductRepository {
  final SupabaseService _supabase;
  final LocalDbService _localDb;

  ProductRepository(this._supabase, this._localDb);

  Future<List<ProductModel>> obtenerProductos({String? linea}) async {
    try {
      final productos = await _supabase.obtenerProductos(linea: linea);
      await _localDb.guardarProductos(productos);
      return productos;
    } catch (e) {
      debugPrint('Error al obtener productos de Supabase: $e');
    }
    return _localDb.obtenerProductos(linea: linea);
  }

  Future<List<String>> obtenerLineas() async {
    return _supabase.obtenerLineas();
  }

  Future<PriceModel?> obtenerPrecio(int productoId, String tipoVendedor) async {
    if (_supabase.currentUser != null) {
      try {
        final precio = await _supabase.obtenerPrecio(productoId, tipoVendedor);
        if (precio != null) return precio;
      } catch (e) {
        debugPrint('Error al obtener precio de Supabase: $e');
      }
    }
    return _localDb.obtenerPrecio(productoId, tipoVendedor);
  }
}
