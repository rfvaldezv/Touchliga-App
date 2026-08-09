import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/design_system/theme/app_theme.dart';
import 'router/app_router.dart';

class TouchligaApp extends ConsumerWidget {
  const TouchligaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Touchliga',
      theme: AppTheme.light(),
      routerConfig: router,
    );
  }
}
