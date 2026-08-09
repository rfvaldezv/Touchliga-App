class AnuncioModel {
  const AnuncioModel({
    required this.id,
    required this.titulo,
    required this.contenido,
    this.imagenUrl,
    required this.autorNombre,
    required this.fechaPublicacion,
    required this.reacciones,
    this.miReaccion,
  });

  final int id;
  final String titulo;
  final String contenido;
  final String? imagenUrl;
  final String autorNombre;
  final DateTime fechaPublicacion;
  final Map<String, int> reacciones;
  final String? miReaccion;

  factory AnuncioModel.fromJson(Map<String, dynamic> json) {
    return AnuncioModel(
      id: (json['id'] as num).toInt(),
      titulo: (json['titulo'] ?? '').toString(),
      contenido: (json['contenido'] ?? '').toString(),
      imagenUrl: json['imagenUrl']?.toString(),
      autorNombre: (json['autorNombre'] ?? '').toString(),
      fechaPublicacion: DateTime.tryParse(json['fechaPublicacion']?.toString() ?? '') ?? DateTime.now(),
      reacciones: (json['reacciones'] as Map?)?.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          ) ??
          const {},
      miReaccion: json['miReaccion']?.toString(),
    );
  }
}
