class PatrocinadorModel {
  const PatrocinadorModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.orden,
    required this.activo,
    this.enlaceUrl,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final String? enlaceUrl;
  final int orden;
  final bool activo;

  factory PatrocinadorModel.fromJson(Map<String, dynamic> json) {
    return PatrocinadorModel(
      id: (json['id'] as num).toInt(),
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      imagenUrl: (json['imagenUrl'] ?? '').toString(),
      enlaceUrl: json['enlaceUrl']?.toString(),
      orden: (json['orden'] as num).toInt(),
      activo: json['activo'] ?? false,
    );
  }
}
