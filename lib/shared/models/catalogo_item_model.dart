/// Forma común a los catálogos simples del backend
/// (Ciudad, País, Estado, Categoría, etc.): id/codigo/nombre/descripcion/activo.
class CatalogoItemModel {
  const CatalogoItemModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.activo,
  });

  final int id;
  final String codigo;
  final String nombre;
  final String descripcion;
  final bool activo;

  factory CatalogoItemModel.fromJson(Map<String, dynamic> json) {
    return CatalogoItemModel(
      id: (json['id'] as num).toInt(),
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      activo: json['activo'] ?? false,
    );
  }
}
