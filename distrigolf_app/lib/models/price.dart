class PriceModel {
  final int id;
  final int productoId;
  final String? esquema;
  final double bruto;
  final double unitario;
  final double maxDescuento;
  final double minimo;
  final double impuestos;

  PriceModel({
    required this.id,
    required this.productoId,
    this.esquema,
    required this.bruto,
    required this.unitario,
    required this.maxDescuento,
    required this.minimo,
    required this.impuestos,
  });

  factory PriceModel.fromMap(Map<String, dynamic> map) {
    return PriceModel(
      id: map['id'] as int,
      productoId: map['producto_id'] as int,
      esquema: map['esquema'] as String?,
      bruto: (map['bruto'] as num).toDouble(),
      unitario: (map['unitario'] as num).toDouble(),
      maxDescuento: (map['max_descuento'] as num?)?.toDouble() ?? 0,
      minimo: (map['minimo'] as num?)?.toDouble() ?? 0,
      impuestos: (map['impuestos'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producto_id': productoId,
      'esquema': esquema,
      'bruto': bruto,
      'unitario': unitario,
      'max_descuento': maxDescuento,
      'minimo': minimo,
      'impuestos': impuestos,
    };
  }
}
