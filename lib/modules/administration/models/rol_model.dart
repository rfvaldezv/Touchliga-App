class RolModel {
  const RolModel({required this.id, required this.nombre, required this.descripcion});

  final int id;
  final String nombre;
  final String descripcion;

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
    );
  }
}
