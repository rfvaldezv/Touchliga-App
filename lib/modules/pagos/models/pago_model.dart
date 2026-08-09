class PagoModel {
  const PagoModel({
    required this.id,
    required this.usuarioId,
    required this.temporadaId,
    required this.monto,
    required this.metodoPago,
    required this.fechaPago,
    this.referencia,
  });

  final int id;
  final int usuarioId;
  final int temporadaId;
  final double monto;
  final String metodoPago;
  final DateTime fechaPago;
  final String? referencia;

  factory PagoModel.fromJson(Map<String, dynamic> json) {
    return PagoModel(
      id: (json['id'] as num).toInt(),
      usuarioId: (json['usuarioId'] as num).toInt(),
      temporadaId: (json['temporadaId'] as num).toInt(),
      monto: (json['monto'] as num).toDouble(),
      metodoPago: (json['metodoPago'] ?? '').toString(),
      fechaPago: DateTime.tryParse(json['fechaPago']?.toString() ?? '') ?? DateTime.now(),
      referencia: json['referencia']?.toString(),
    );
  }
}
