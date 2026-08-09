class MiPerfilModel {
  const MiPerfilModel({
    required this.nombre,
    required this.apellidos,
    required this.correo,
    required this.sexo,
    this.fechaNacimiento,
    this.nickname,
    this.equipoFavoritoId,
    this.equipoFavoritoNombre,
    this.fotoUrl,
  });

  final String nombre;
  final String apellidos;
  final String correo;
  final String sexo;
  final DateTime? fechaNacimiento;
  final String? nickname;
  final int? equipoFavoritoId;
  final String? equipoFavoritoNombre;
  final String? fotoUrl;

  factory MiPerfilModel.fromJson(Map<String, dynamic> json) {
    return MiPerfilModel(
      nombre: (json['nombre'] ?? '').toString(),
      apellidos: (json['apellidos'] ?? '').toString(),
      correo: (json['correo'] ?? '').toString(),
      sexo: (json['sexo'] ?? '').toString(),
      fechaNacimiento: json['fechaNacimiento'] != null
          ? DateTime.tryParse(json['fechaNacimiento'].toString())
          : null,
      nickname: json['nickname']?.toString(),
      equipoFavoritoId: (json['equipoFavoritoId'] as num?)?.toInt(),
      equipoFavoritoNombre: json['equipoFavoritoNombre']?.toString(),
      fotoUrl: json['fotoUrl']?.toString(),
    );
  }
}
