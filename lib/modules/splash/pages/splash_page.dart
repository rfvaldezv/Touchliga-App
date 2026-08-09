import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/asset_paths.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../login/providers/auth_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Tiempo mínimo para mostrar el Splash.
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Inicializa el estado de autenticación.
    // El GoRouter decidirá automáticamente si navegar
    // al Login o al Dashboard mediante el redirect().
    await ref.read(authProvider.notifier).checkSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // El logo y el tagline "PASIÓN · RESPETO · UNIÓN" ya vienen
          // dibujados dentro de esta imagen — no hay que dibujarlos
          // otra vez encima, o se ven duplicados/encimados.
          Image.asset(AssetPaths.splashBackground, fit: BoxFit.cover),

          SafeArea(
            child: Align(
              alignment: const Alignment(0, 0.72),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.secondary),
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Versión 1.0',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
