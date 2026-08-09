import 'pago_model.dart';

class ResumenPagoModel {
  const ResumenPagoModel({
    required this.cuota,
    required this.totalPagado,
    required this.saldoPendiente,
    required this.pagoCompleto,
    required this.pagos,
  });

  final double cuota;
  final double totalPagado;
  final double saldoPendiente;
  final bool pagoCompleto;
  final List<PagoModel> pagos;

  factory ResumenPagoModel.fromJson(Map<String, dynamic> json) {
    return ResumenPagoModel(
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
