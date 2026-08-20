import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class LoginFormWidget extends ConsumerStatefulWidget {
  const LoginFormWidget({super.key});

  @override
  ConsumerState<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends ConsumerState<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _mostrarPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¡Bienvenido de nuevo!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Inicia sesión para continuar',
              style: TextStyle(color: Colors.black54),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            TextFormField(
              controller: _emailController,
              enabled: !state.loading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Correo electrónico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Ingrese el correo electrónico';
                }

                if (!value.contains('@')) {
                  return 'Correo electrónico inválido';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: _passwordController,
              enabled: !state.loading,
              obscureText: !_mostrarPassword,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _mostrarPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  ),
                  onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese la contraseña';
                }

                // Sin mínimo de longitud aquí -- por consistencia con
                // FutLiga, donde algunos participantes migrados
                // heredaron contraseñas cortas. El mínimo de 6 solo
                // aplica al crear/restablecer, no al iniciar sesión.
                return null;
              },
              onFieldSubmitted: (_) async {
                await _login();
              },
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: state.loading
                    ? null
                    : () async {
                        await _login();
                      },
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: state.loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : const Text('Iniciar sesión'),
              ),
            ),

            if (state.errorMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                state.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final ok = await ref
        .read(authProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bienvenido a Touchliga')));

      // En el siguiente entregable sustituiremos este SnackBar
      // por la navegación automática al Dashboard mediante GoRouter.
    }
  }
}
