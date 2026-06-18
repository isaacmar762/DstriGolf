class UserModel {
  final String id;
  final String email;
  final String nombre;
  final String? telefono;
  final String tipoVendedor;
  final bool activo;

  UserModel({
    required this.id,
    required this.email,
    required this.nombre,
    this.telefono,
    required this.tipoVendedor,
    this.activo = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      nombre: map['nombre'] as String,
      telefono: map['telefono'] as String?,
      tipoVendedor: map['tipo_vendedor'] as String,
      activo: map['activo'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nombre': nombre,
      'telefono': telefono,
      'tipo_vendedor': tipoVendedor,
      'activo': activo,
    };
  }

  bool get esMayorista => tipoVendedor == 'MAYORISTA';
  bool get esTAT => tipoVendedor == 'TAT';
  bool get esAdmin => tipoVendedor == 'ADMIN';
}
