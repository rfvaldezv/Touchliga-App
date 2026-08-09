import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/constants/asset_paths.dart';
import '../../../shared/design_system/tokens/app_radius.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../providers/auth_provider.dart';
import '../widgets/login_form_widget.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authProvider, (previous, next) {
      if (next.authenticated && previous?.authenticated != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicio de sesión correcto'),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!next.loading &&
          next.errorMessage != null &&
          next.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mismo fondo que el Splash — ya trae el logo dibujado
          // arriba, así que la transición Splash → Login se siente
          // continua en vez de un salto brusco de estilo.
          Image.asset(AssetPaths.splashBackground, fit: BoxFit.cover),

          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Column(
                  children: [
                    // Deja ver el logo/tagline ya dibujados en la
                    // parte de arriba de la imagen de fondo antes de
                    // que empiece la tarjeta del formulario.
                    const SizedBox(height: 260),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Card(
                        color: Colors.white,
                        elevation: 12,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: const LoginFormWidget(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
