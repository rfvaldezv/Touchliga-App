class ParticipantePendienteModel {
  const ParticipantePendienteModel({
    required this.usuarioId,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.partidosCapturados,
    required this.totalPartidos,
  });

  final int usuarioId;
  final String nombre;
  final String correo;
  final String? telefono;
  final int partidosCapturados;
  final int totalPartidos;

  bool get sinNada => partidosCapturados == 0;
  int get faltantes => totalPartidos - partidosCapturados;

  factory ParticipantePendienteModel.fromJson(Map<String, dynamic> json) {
    return ParticipantePendienteModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: json['nombre']?.toString() ?? '',
      correo: json['correo']?.toString() ?? '',
      telefono: json['telefono']?.toString(),
      partidosCapturados: (json['partidosCapturados'] as num?)?.toInt() ?? 0,
      totalPartidos: (json['totalPartidos'] as num?)?.toInt() ?? 0,
    );
  }
}
