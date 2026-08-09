class EquipoModel {
  const EquipoModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    this.escudoUrl,
    this.apodo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final bool activo;
  final String? escudoUrl;
  final String? apodo;

  factory EquipoModel.fromJson(Map<String, dynamic> json) {
    return EquipoModel(
      id: json['id'] is int ? json['id'] as int : int.tryParse(json['id'].toString()) ?? 0,
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: json['activo'] ?? false,
      escudoUrl: json['escudoUrl']?.toString(),
      apodo: json['apodo']?.toString(),
    );
  }
}
