class EstatusPagoModel {
  const EstatusPagoModel({
    required this.usuarioId,
    required this.usuarioNombre,
    required this.cuota,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.pagoCompleto,
  });

  final int usuarioId;
  final String usuarioNombre;
  final double cuota;
  final double totalPagado;
  final double saldoPendiente;
  final bool pagoCompleto;

  factory EstatusPagoModel.fromJson(Map<String, dynamic> json) {
    return EstatusPagoModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: (json['usuarioNombre'] ?? '').toString(),
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      totalPagado: (json['totalPagado'] as num?)?.toDouble() ?? 0,
      saldoPendiente: (json['saldoPendiente'] as num?)?.toDouble() ?? 0,
      pagoCompleto: json['pagoCompleto'] ?? false,
    );
  }
}
