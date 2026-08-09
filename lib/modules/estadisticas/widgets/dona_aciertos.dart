import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Gráfica de dona hecha a mano con CustomPaint — sin librerías
/// externas, para no meter otra dependencia con riesgo de
/// compatibilidad. En Touchliga solo hay acertó/no acertó (no hay
/// "exacto" porque no se predice marcador).
class DonaAciertos extends StatelessWidget {
  const DonaAciertos({
    super.key,
    required this.acertados,
    required this.fallados,
  });

  final int acertados;
  final int fallados;

  int get total => acertados + fallados;

  @override
  Widget build(BuildContext context) {
    if (total == 0) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Todavía no hay pronósticos calificados.')),
      );
    }

    return Row(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CustomPaint(
            painter: _DonaPainter(acertados: acertados, fallados: fallados),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$total', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('pronósticos', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Leyenda(color: const Color(0xFF31F077), etiqueta: 'Acertados', valor: acertados),
              _Leyenda(color: const Color(0xFFFF1307), etiqueta: 'Fallados', valor: fallados),
            ],
          ),
        ),
      ],
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.color, required this.etiqueta, required this.valor});

  final Color color;
  final String etiqueta;
  final int valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text('$etiqueta: $valor'),
        ],
      ),
    );
  }
}

class _DonaPainter extends CustomPainter {
  _DonaPainter({required this.acertados, required this.fallados});

  final int acertados;
  final int fallados;

  @override
  void paint(Canvas canvas, Size size) {
    final total = acertados + fallados;
    if (total == 0) return;

    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width / 2;
    const grosor = 18.0;

    final valores = [acertados, fallados];
    final colores = [const Color(0xFF31F077), const Color(0xFFFF1307)];

    var anguloInicial = -math.pi / 2;

    for (var i = 0; i < valores.length; i++) {
      if (valores[i] == 0) continue;

      final barrido = (valores[i] / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colores[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = grosor
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: centro, radius: radio - grosor / 2),
        anguloInicial,
        barrido,
        false,
        paint,
      );

      anguloInicial += barrido;
    }
  }

  @override
  bool shouldRepaint(covariant _DonaPainter oldDelegate) {
    return oldDelegate.acertados != acertados || oldDelegate.fallados != fallados;
  }
}
