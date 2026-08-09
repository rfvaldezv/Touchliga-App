import 'package:flutter/material.dart';

import '../../core/widgets/app_shell.dart';
import '../../core/widgets/app_drawer.dart';
import '../../core/widgets/app_bottom_navigation.dart';

class DashboardLayout extends StatelessWidget {
  const DashboardLayout({
    super.key,
    required this.title,
    required this.body,
    this.selectedIndex = 0,
  });

  final String title;
  final Widget body;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: title,

      drawer: const AppDrawer(),

      bottomNavigationBar: AppBottomNavigation(
        index: selectedIndex,
        onTap: (index) {
          // TODO: Navegación con GoRouter
        },
      ),

      body: body,
    );
  }
}
