class ConfiguracionPremioModel {
  const ConfiguracionPremioModel({
    this.id,
    required this.posicion,
    required this.tipoPremio,
    required this.monto,
    this.descripcion,
  });

  final int? id;
  final int posicion;
  final String tipoPremio; // "Efectivo" o "Especie"
  final double monto;
  final String? descripcion;

  ConfiguracionPremioModel copyWith({
    String? tipoPremio,
    double? monto,
    String? descripcion,
  }) {
    return ConfiguracionPremioModel(
      id: id,
      posicion: posicion,
      tipoPremio: tipoPremio ?? this.tipoPremio,
      monto: monto ?? this.monto,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  factory ConfiguracionPremioModel.fromJson(Map<String, dynamic> json) {
    return ConfiguracionPremioModel(
      id: (json['id'] as num?)?.toInt(),
      posicion: (json['posicion'] as num).toInt(),
      tipoPremio: (json['tipoPremio'] ?? 'Efectivo').toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      descripcion: json['descripcion']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'posicion': posicion,
        'tipoPremio': tipoPremio,
        'monto': monto,
        'descripcion': descripcion,
      };
}
