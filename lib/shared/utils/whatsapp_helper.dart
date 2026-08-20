import 'dart:math';

/// Espera un tiempo ALEATORIO entre 0 y 15 segundos -- necesario
/// entre cada envío masivo de WhatsApp, para que el patrón no se
/// vea perfectamente regular (WhatsApp puede bloquear envíos que
/// detecta como automatizados/masivos si son muy predecibles).
Future<void> esperarAntesDelSiguienteWhatsApp() async {
  final milisegundos = Random().nextInt(15000);
  await Future.delayed(Duration(milliseconds: milisegundos));
}
