import 'pago_model.dart';

class CuentaCorrienteTemporadaModel {
  const CuentaCorrienteTemporadaModel({
    required this.temporadaId,
    required this.temporadaNombre,
    required this.cuota,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.pagoCompleto,
    required this.pagos,
  });

  final int temporadaId;
  final String temporadaNombre;
  final double cuota;
  final double totalPagado;
  final double saldoPendiente;
  final bool pagoCompleto;
  final List<PagoModel> pagos;

  factory CuentaCorrienteTemporadaModel.fromJson(Map<String, dynamic> json) {
    return CuentaCorrienteTemporadaModel(
      temporadaId: (json['temporadaId'] as num).toInt(),
      temporadaNombre: (json['temporadaNombre'] ?? '').toString(),
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      totalPagado: (json['totalPagado'] as num?)?.toDouble() ?? 0,
      saldoPendiente: (json['saldoPendiente'] as num?)?.toDouble() ?? 0,
      pagoCompleto: json['pagoCompleto'] ?? false,
      pagos: (json['pagos'] as List? ?? [])
          .map((p) => PagoModel.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CuentaCorrienteModel {
  const CuentaCorrienteModel({
    required this.usuarioId,
    required this.usuarioNombre,
    required this.totalAdeudado,
    required this.totalPagado,
    required this.saldoTotal,
    required this.temporadas,
  });

  final int usuarioId;
  final String usuarioNombre;
  final double totalAdeudado;
  final double totalPagado;
  final double saldoTotal;
  final List<CuentaCorrienteTemporadaModel> temporadas;

  factory CuentaCorrienteModel.fromJson(Map<String, dynamic> json) {
    return CuentaCorrienteModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      usuarioNombre: (json['usuarioNombre'] ?? '').toString(),
      totalAdeudado: (json['totalAdeudado'] as num?)?.toDouble() ?? 0,
      totalPagado: (json['totalPagado'] as num?)?.toDouble() ?? 0,
      saldoTotal: (json['saldoTotal'] as num?)?.toDouble() ?? 0,
      temporadas: (json['temporadas'] as List? ?? [])
          .map((t) => CuentaCorrienteTemporadaModel.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}
