class ProductModel {
  final int id;
  final String referencia;
  final String nombre;
  final String? codLinea;
  final String? nombreLinea;
  final String? codMedida;
  final double? volumen;
  final double? grados;
  final String? imagenUrl;

  ProductModel({
    required this.id,
    required this.referencia,
    required this.nombre,
    this.codLinea,
    this.nombreLinea,
    this.codMedida,
    this.volumen,
    this.grados,
    this.imagenUrl,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'] as int,
      referencia: map['referencia'] as String,
      nombre: map['nombre'] as String,
      codLinea: map['cod_linea'] as String?,
      nombreLinea: map['nombre_linea'] as String?,
      codMedida: map['cod_medida'] as String?,
      volumen: (map['volumen'] as num?)?.toDouble(),
      grados: (map['grados'] as num?)?.toDouble(),
      imagenUrl: map['imagen_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'referencia': referencia,
      'nombre': nombre,
      'cod_linea': codLinea,
      'nombre_linea': nombreLinea,
      'cod_medida': codMedida,
      'volumen': volumen,
      'grados': grados,
      'imagen_url': imagenUrl,
    };
  }
}
