import 'package:flutter/material.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,

    required this.title,

    required this.body,

    this.drawer,

    this.bottomNavigationBar,

    this.floatingActionButton,
  });

  final String title;

  final Widget body;

  final Widget? drawer;

  final Widget? bottomNavigationBar;

  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),

      drawer: drawer,

      floatingActionButton: floatingActionButton,

      bottomNavigationBar: bottomNavigationBar,

      body: SafeArea(child: body),
    );
  }
}
