import 'package:flutter/material.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.body,
    this.drawer,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final Widget? drawer;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,

      appBar: AppBar(title: Text(title), centerTitle: true),

      body: SafeArea(child: body),

      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
