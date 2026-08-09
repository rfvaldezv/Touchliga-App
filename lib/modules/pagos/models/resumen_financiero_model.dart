class DesgloseMetodoPagoModel {
  const DesgloseMetodoPagoModel({
    required this.metodoPago,
    required this.cantidad,
    required this.monto,
  });

  final String metodoPago;
  final int cantidad;
  final double monto;

  factory DesgloseMetodoPagoModel.fromJson(Map<String, dynamic> json) {
    return DesgloseMetodoPagoModel(
      metodoPago: (json['metodoPago'] ?? '').toString(),
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
    );
  }
}

class TransaccionModel {
  const TransaccionModel({
    required this.id,
    required this.usuarioNombre,
    required this.monto,
    required this.metodoPago,
    required this.fechaPago,
    this.referencia,
  });

  final int id;
  final String usuarioNombre;
  final double monto;
  final String metodoPago;
  final DateTime fechaPago;
  final String? referencia;

  factory TransaccionModel.fromJson(Map<String, dynamic> json) {
    return TransaccionModel(
      id: (json['id'] as num).toInt(),
      usuarioNombre: (json['usuarioNombre'] ?? '').toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      metodoPago: (json['metodoPago'] ?? '').toString(),
      fechaPago: DateTime.tryParse(json['fechaPago']?.toString() ?? '') ?? DateTime.now(),
      referencia: json['referencia']?.toString(),
    );
  }
}

class ResumenFinancieroModel {
  const ResumenFinancieroModel({
    required this.cuota,
    required this.totalParticipantes,
    required this.participantesCubiertos,
    required this.totalEsperado,
    required this.totalRecaudado,
    required this.totalPendiente,
    required this.desglosePorMetodo,
    required this.ultimasTransacciones,
  });

  final double cuota;
  final int totalParticipantes;
  final int participantesCubiertos;
  final double totalEsperado;
  final double totalRecaudado;
  final double totalPendiente;
  final List<DesgloseMetodoPagoModel> desglosePorMetodo;
  final List<TransaccionModel> ultimasTransacciones;

  double get porcentajeCubierto =>
      totalParticipantes > 0 ? (participantesCubiertos / totalParticipantes) * 100 : 0;

  factory ResumenFinancieroModel.fromJson(Map<String, dynamic> json) {
    return ResumenFinancieroModel(
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      totalParticipantes: (json['totalParticipantes'] as num?)?.toInt() ?? 0,
      participantesCubiertos: (json['participantesCubiertos'] as num?)?.toInt() ?? 0,
      totalEsperado: (json['totalEsperado'] as num?)?.toDouble() ?? 0,
      totalRecaudado: (json['totalRecaudado'] as num?)?.toDouble() ?? 0,
      totalPendiente: (json['totalPendiente'] as num?)?.toDouble() ?? 0,
      desglosePorMetodo: (json['desglosePorMetodo'] as List? ?? [])
          .map((d) => DesgloseMetodoPagoModel.fromJson(d as Map<String, dynamic>))
          .toList(),
      ultimasTransacciones: (json['ultimasTransacciones'] as List? ?? [])
          .map((t) => TransaccionModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
