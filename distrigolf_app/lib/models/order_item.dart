import 'product.dart';

class OrderItemModel {
  final int? id;
  final String? pedidoId;
  final int productoId;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  final ProductModel? producto;

  OrderItemModel({
    this.id,
    this.pedidoId,
    required this.productoId,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.producto,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      id: map['id'] as int?,
      pedidoId: map['pedido_id'] as String?,
      productoId: map['producto_id'] as int,
      cantidad: map['cantidad'] as int,
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
      producto: map['producto'] != null
          ? ProductModel.fromMap(map['producto'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pedido_id': pedidoId,
      'producto_id': productoId,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }
}
