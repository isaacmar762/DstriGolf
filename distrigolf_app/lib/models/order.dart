import 'client.dart';
import 'order_item.dart';

class OrderModel {
  final String? id;
  final String? vendedorId;
  final int? clienteId;
  final DateTime? fecha;
  final String estado;
  final double total;
  final String? firma;
  final String? notas;
  final double? latitud;
  final double? longitud;

  final ClientModel? cliente;
  final List<OrderItemModel>? items;

  OrderModel({
    this.id,
    this.vendedorId,
    this.clienteId,
    this.fecha,
    this.estado = 'BORRADOR',
    this.total = 0,
    this.firma,
    this.notas,
    this.latitud,
    this.longitud,
    this.cliente,
    this.items,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    return OrderModel(
      id: map['id'] as String?,
      vendedorId: map['vendedor_id'] as String?,
      clienteId: map['cliente_id'] as int?,
      fecha: map['fecha'] != null ? DateTime.parse(map['fecha'] as String) : null,
      estado: map['estado'] as String? ?? 'BORRADOR',
      total: (map['total'] as num?)?.toDouble() ?? 0,
      firma: map['firma'] as String?,
      notas: map['notas'] as String?,
      latitud: (map['latitud'] as num?)?.toDouble(),
      longitud: (map['longitud'] as num?)?.toDouble(),
      cliente: map['cliente'] != null
          ? ClientModel.fromMap(map['cliente'] as Map<String, dynamic>)
          : null,
      items: map['items'] != null
          ? (map['items'] as List)
              .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'vendedor_id': vendedorId,
      'cliente_id': clienteId,
      'fecha': fecha?.toIso8601String(),
      'estado': estado,
      'total': total,
      'firma': firma,
      'notas': notas,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  bool get esBorrador => estado == 'BORRADOR';
  bool get esConfirmado => estado == 'CONFIRMADO';
  bool get esSincronizado => estado == 'SINCRONIZADO';
  bool get esEntregado => estado == 'ENTREGADO';
}
