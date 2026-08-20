import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/communication/providers/communication_provider.dart';

class AppBottomNavigation extends ConsumerWidget {
  const AppBottomNavigation({
    super.key,
    required this.index,
    required this.onTap,
  });

  final int index;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noLeidosAsync = ref.watch(mensajesNoLeidosProvider);
    final noLeidos = noLeidosAsync.value ?? 0;

    return NavigationBar(
      selectedIndex: index,

      destinations: [
        const NavigationDestination(icon: Icon(Icons.home), label: "Inicio"),

        NavigationDestination(
          icon: noLeidos > 0
              ? Badge(
                  label: Text(noLeidos > 9 ? '9+' : '$noLeidos'),
                  child: const Icon(Icons.chat_bubble_outline),
                )
              : const Icon(Icons.chat_bubble_outline),
          label: "Mensajes",
        ),

        const NavigationDestination(icon: Icon(Icons.emoji_events), label: "Premios"),

        const NavigationDestination(
          icon: Icon(Icons.bar_chart),
          label: "Estadísticas",
        ),

        const NavigationDestination(icon: Icon(Icons.person), label: "Perfil"),
      ],

      onDestinationSelected: (i) {
        onTap(i);
        // Al entrar a Mensajes, se refresca el conteo -- así, en
        // cuanto regrese (ya leído), el globo desaparece solo.
        if (i == 1) {
          Future.delayed(const Duration(milliseconds: 500), () {
            ref.invalidate(mensajesNoLeidosProvider);
          });
        }
      },
    );
  }
}
