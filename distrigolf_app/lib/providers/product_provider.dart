import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/price.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  List<ProductModel> _productos = [];
  List<String> _lineas = [];
  String? _lineaSeleccionada;
  bool _loading = false;
  String? _error;
  String _busqueda = '';
  Map<int, PriceModel> _precios = {};

  ProductProvider(this._repository);

  List<ProductModel> get productos => _filtrarProductos();
  List<String> get lineas => _lineas;
  String? get lineaSeleccionada => _lineaSeleccionada;
  bool get loading => _loading;
  String? get error => _error;

  List<ProductModel> _filtrarProductos() {
    var result = _productos;

    if (_lineaSeleccionada != null) {
      final target = _lineaSeleccionada!.trim();
      result = result
          .where((p) => p.nombreLinea?.trim() == target)
          .toList();
    }

    if (_busqueda.isNotEmpty) {
      final query = _busqueda.toLowerCase();
      result = result.where((p) {
        return p.nombre.toLowerCase().contains(query) ||
            p.referencia.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  Future<void> cargarProductos({String? linea}) async {
    _loading = true;
    _error = null;
    _precios.clear();
    notifyListeners();

    try {
      _productos = await _repository.obtenerProductos();
    } catch (e) {
      _error = e.toString();
    }
    try {
      _lineas = await _repository.obtenerLineas();
    } catch (e) {
      _error = (_error ?? '') + 'Lineas: $e';
    }

    _loading = false;
    notifyListeners();
  }

  Future<PriceModel?> obtenerPrecio(int productoId, String tipoVendedor) async {
    if (_precios.containsKey(productoId)) {
      return _precios[productoId];
    }
    final precio = await _repository.obtenerPrecio(productoId, tipoVendedor);
    if (precio != null) {
      _precios[productoId] = precio;
    }
    return precio;
  }

  void setLinea(String? linea) {
    _lineaSeleccionada = linea;
    notifyListeners();
  }

  void setBusqueda(String busqueda) {
    _busqueda = busqueda;
    notifyListeners();
  }
}
