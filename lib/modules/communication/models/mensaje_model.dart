class MensajeModel {
  const MensajeModel({
    required this.id,
    required this.remitenteId,
    required this.destinatarioId,
    required this.contenido,
    this.imagenUrl,
    required this.fechaEnvio,
    required this.leido,
    required this.esMio,
  });

  final int id;
  final int remitenteId;
  final int destinatarioId;
  final String contenido;
  final String? imagenUrl;
  final DateTime fechaEnvio;
  final bool leido;
  final bool esMio;

  factory MensajeModel.fromJson(Map<String, dynamic> json) {
    return MensajeModel(
      id: (json['id'] as num).toInt(),
      remitenteId: (json['remitenteId'] as num).toInt(),
      destinatarioId: (json['destinatarioId'] as num).toInt(),
      contenido: (json['contenido'] ?? '').toString(),
      imagenUrl: json['imagenUrl']?.toString(),
      fechaEnvio: DateTime.tryParse(json['fechaEnvio']?.toString() ?? '') ?? DateTime.now(),
      leido: json['leido'] ?? false,
      esMio: json['esMio'] ?? false,
    );
  }
}
