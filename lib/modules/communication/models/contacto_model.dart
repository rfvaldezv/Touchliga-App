class ContactoModel {
  const ContactoModel({
    required this.usuarioId,
    required this.nombre,
    required this.ultimoMensaje,
    required this.fechaUltimoMensaje,
    required this.tieneNoLeidos,
    required this.roles,
  });

  final int usuarioId;
  final String nombre;
  final String ultimoMensaje;
  final DateTime fechaUltimoMensaje;
  final bool tieneNoLeidos;
  final List<String> roles;

  factory ContactoModel.fromJson(Map<String, dynamic> json) {
    return ContactoModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      ultimoMensaje: (json['ultimoMensaje'] ?? '').toString(),
      fechaUltimoMensaje: DateTime.tryParse(json['fechaUltimoMensaje']?.toString() ?? '') ?? DateTime.now(),
      tieneNoLeidos: json['tieneNoLeidos'] ?? false,
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
