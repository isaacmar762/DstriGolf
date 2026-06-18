import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/price.dart';
import '../models/order.dart';
import '../models/order_item.dart';
import '../repositories/order_repository.dart';

class CartItem {
  final ProductModel product;
  final PriceModel price;
  int quantity;

  CartItem({
    required this.product,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => quantity * price.unitario;
}

class OrderProvider extends ChangeNotifier {
  final OrderRepository _repository;

  List<OrderModel> _pedidos = [];
  OrderModel? _pedidoActual;
  ClientModel? _clienteSeleccionado;
  List<CartItem> _carrito = [];
  bool _loading = false;
  String? _error;
  String? _firmaBase64;
  String? _notas;

  OrderProvider(this._repository);

  List<OrderModel> get pedidos => _pedidos;
  OrderModel? get pedidoActual => _pedidoActual;
  ClientModel? get clienteSeleccionado => _clienteSeleccionado;
  List<CartItem> get carrito => _carrito;
  bool get loading => _loading;
  String? get error => _error;
  String? get firmaBase64 => _firmaBase64;
  String? get notas => _notas;
  int get itemCount => _carrito.fold(0, (sum, item) => sum + item.quantity);
  double get totalCarrito =>
      _carrito.fold(0.0, (sum, item) => sum + item.subtotal);

  bool get carritoVacio => _carrito.isEmpty;
  bool get tieneCliente => _clienteSeleccionado != null;

  void seleccionarCliente(ClientModel cliente) {
    _clienteSeleccionado = cliente;
    notifyListeners();
  }

  void agregarAlCarrito(ProductModel product, PriceModel price) {
    final index = _carrito.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _carrito[index].quantity++;
    } else {
      _carrito.add(CartItem(product: product, price: price));
    }
    notifyListeners();
  }

  void actualizarCantidad(int productId, int cantidad) {
    final index = _carrito.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (cantidad <= 0) {
        _carrito.removeAt(index);
      } else {
        _carrito[index].quantity = cantidad;
      }
      notifyListeners();
    }
  }

  void eliminarDelCarrito(int productId) {
    _carrito.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void setFirma(String? firma) {
    _firmaBase64 = firma;
    notifyListeners();
  }

  void setNotas(String notas) {
    _notas = notas;
    notifyListeners();
  }

  void limpiarCarrito() {
    _carrito.clear();
    _clienteSeleccionado = null;
    _firmaBase64 = null;
    _notas = null;
    notifyListeners();
  }

  Future<String?> confirmarPedido(String userId) async {
    if (_clienteSeleccionado == null || _carrito.isEmpty) return null;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final pedido = OrderModel(
        vendedorId: userId,
        clienteId: _clienteSeleccionado!.id,
        estado: 'BORRADOR',
        total: totalCarrito,
        firma: _firmaBase64,
        notas: _notas,
      );

      final items = _carrito.map((item) => OrderItemModel(
            productoId: item.product.id,
            cantidad: item.quantity,
            precioUnitario: item.price.unitario,
            subtotal: item.subtotal,
          )).toList();

      final pedidoId = await _repository.crearPedido(pedido, items);

      limpiarCarrito();
      return pedidoId;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> agregarFirmaAPedido(String pedidoId) async {
    if (_firmaBase64 == null) return;
    await _repository.agregarFirmaAPedido(pedidoId, _firmaBase64!);
  }

  Future<void> confirmarPedidoExistente(String pedidoId) async {
    await _repository.confirmarPedidoExistente(pedidoId);
  }

  Future<void> cargarPedidos(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _pedidos = await _repository.obtenerPedidos(userId);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> cargarPedido(String id) async {
    _loading = true;
    notifyListeners();

    _pedidoActual = await _repository.obtenerPedido(id);

    _loading = false;
    notifyListeners();
  }
}
