class ClientModel {
  final int id;
  final String? codigo;
  final String? dv;
  final String nombre;
  final String? direccion;
  final String? email;
  final String? ciudad;
  final int? zonaId;
  final String? zonaNombre;

  ClientModel({
    required this.id,
    this.codigo,
    this.dv,
    required this.nombre,
    this.direccion,
    this.email,
    this.ciudad,
    this.zonaId,
    this.zonaNombre,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map) {
    return ClientModel(
      id: map['id'] as int,
      codigo: map['codigo'] as String?,
      dv: map['dv'] as String?,
      nombre: map['nombre'] as String,
      direccion: map['direccion'] as String?,
      email: map['email'] as String?,
      ciudad: map['ciudad'] as String?,
      zonaId: map['zona_id'] as int?,
      zonaNombre: map['zona_nombre'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'codigo': codigo,
      'dv': dv,
      'nombre': nombre,
      'direccion': direccion,
      'email': email,
      'ciudad': ciudad,
      'zona_id': zonaId,
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'codigo': codigo,
      'dv': dv,
      'nombre': nombre,
      'direccion': direccion,
      'email': email,
      'ciudad': ciudad,
      'zona_id': zonaId,
      'zona_nombre': zonaNombre,
    };
  }
}
