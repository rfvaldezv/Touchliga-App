import 'package:flutter/material.dart';

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.index,
    required this.onTap,
  });

  final int index;

  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,

      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: "Inicio"),

        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: "Mensajes",
        ),

        NavigationDestination(icon: Icon(Icons.emoji_events), label: "Premios"),

        NavigationDestination(
          icon: Icon(Icons.bar_chart),
          label: "Estadísticas",
        ),

        NavigationDestination(icon: Icon(Icons.person), label: "Perfil"),
      ],

      onDestinationSelected: onTap,
    );
  }
}
