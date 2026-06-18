class SyncLog {
  final int? id;
  final String pedidoId;
  final String accion;
  final String estado;
  final DateTime? createdAt;

  SyncLog({
    this.id,
    required this.pedidoId,
    required this.accion,
    required this.estado,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'pedido_id': pedidoId,
      'accion': accion,
      'estado': estado,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  factory SyncLog.fromMap(Map<String, dynamic> map) {
    return SyncLog(
      id: map['id'] as int?,
      pedidoId: map['pedido_id'] as String,
      accion: map['accion'] as String,
      estado: map['estado'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }
}
