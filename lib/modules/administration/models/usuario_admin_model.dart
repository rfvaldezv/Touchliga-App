class UsuarioAdminModel {
  const UsuarioAdminModel({
    required this.id,
    required this.nombre,
    required this.apellidos,
    required this.telefono,
    required this.correo,
    required this.activo,
    required this.estatus,
    required this.roles,
    this.invitadoPorNombre,
    this.parejaId,
    this.parejaNombre,
    this.nombreEquipo,
    this.correoAlterna,
    this.esCuentaVinculada = false,
    this.ciudadId,
    this.ciudadNombre,
    this.paisId,
    this.paisNombre,
    this.estadoId,
    this.estadoNombre,
  });

  final int id;
  final String nombre;
  final String apellidos;
  final String telefono;
  final String correo;
  final bool activo;
  final String estatus;
  final List<String> roles;
  final String? invitadoPorNombre;
  final int? parejaId;
  final String? parejaNombre;
  final String? nombreEquipo;
  final String? correoAlterna;
  final bool esCuentaVinculada;
  final int? ciudadId;
  final String? ciudadNombre;
  final int? paisId;
  final String? paisNombre;
  final int? estadoId;
  final String? estadoNombre;

  String get nombreCompleto => '$nombre $apellidos'.trim();

  factory UsuarioAdminModel.fromJson(Map<String, dynamic> json) {
    return UsuarioAdminModel(
      id: (json['id'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? '').toString(),
      telefono: (json['telefono'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      activo: json['activo'] ?? false,
      estatus: (json['estatus'] ?? 'Activo').toString(),
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      invitadoPorNombre: json['invitadoPorNombre']?.toString(),
      parejaId: (json['parejaId'] as num?)?.toInt(),
      parejaNombre: json['parejaNombre']?.toString(),
      nombreEquipo: json['nombreEquipo']?.toString(),
      correoAlterna: json['correoAlterna']?.toString(),
      esCuentaVinculada: json['esCuentaVinculada'] ?? false,
      ciudadId: (json['ciudadId'] as num?)?.toInt(),
      ciudadNombre: json['ciudadNombre']?.toString(),
      paisId: (json['paisId'] as num?)?.toInt(),
      paisNombre: json['paisNombre']?.toString(),
      estadoId: (json['estadoId'] as num?)?.toInt(),
      estadoNombre: json['estadoNombre']?.toString(),
    );
  }
}
