import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/theme/app_spacing.dart';
import '../models/configuracion_smtp_model.dart';
import '../providers/configuracion_smtp_provider.dart';

class AdminConfiguracionSmtpPage extends ConsumerWidget {
  const AdminConfiguracionSmtpPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(configuracionSmtpProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de correo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.administration),
        ),
      ),
      body: configAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('No fue posible cargar la configuración.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (config) => _FormularioSmtp(configuracionInicial: config),
      ),
    );
  }
}

class _FormularioSmtp extends ConsumerStatefulWidget {
  const _FormularioSmtp({required this.configuracionInicial});

  final ConfiguracionSmtpModel configuracionInicial;

  @override
  ConsumerState<_FormularioSmtp> createState() => _FormularioSmtpState();
}

class _FormularioSmtpState extends ConsumerState<_FormularioSmtp> {
  late bool _habilitado;
  late final TextEditingController _hostController;
  late final TextEditingController _portController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _fromEmailController;
  late final TextEditingController _fromNameController;
  var _mostrarPassword = false;
  var _guardando = false;

  @override
  void initState() {
    super.initState();
    final c = widget.configuracionInicial;
    _habilitado = c.habilitado;
    _hostController = TextEditingController(text: c.host);
    _portController = TextEditingController(text: c.port.toString());
    _usernameController = TextEditingController(text: c.username);
    _passwordController = TextEditingController(text: c.password);
    _fromEmailController = TextEditingController(text: c.fromEmail);
    _fromNameController = TextEditingController(text: c.fromName);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final nueva = ConfiguracionSmtpModel(
        habilitado: _habilitado,
        host: _hostController.text.trim(),
        port: int.tryParse(_portController.text.trim()) ?? 587,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        fromEmail: _fromEmailController.text.trim(),
        fromName: _fromNameController.text.trim(),
      );

      await ref.read(configuracionSmtpServiceProvider).guardar(nueva);
      ref.invalidate(configuracionSmtpProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de correo guardada.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aquí se controla desde dónde se mandan los correos de bienvenida y aviso de '
            'actualización a los participantes. Los cambios aplican de inmediato, sin '
            'necesitar publicar de nuevo el servidor.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: AppSpacing.lg),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Envío de correos activado'),
            subtitle: const Text('Si está apagado, los correos no se mandan (solo se registran en el log).'),
            value: _habilitado,
            onChanged: (value) => setState(() => _habilitado = value),
          ),
          const Divider(height: 32),

          TextField(
            controller: _hostController,
            decoration: const InputDecoration(labelText: 'Servidor (Host)', hintText: 'mail.smtp2go.com'),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _portController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Puerto', hintText: '587'),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(labelText: 'Usuario SMTP'),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _passwordController,
            obscureText: !_mostrarPassword,
            decoration: InputDecoration(
              labelText: 'Contraseña SMTP',
              suffixIcon: IconButton(
                icon: Icon(_mostrarPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _mostrarPassword = !_mostrarPassword),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          TextField(
            controller: _fromEmailController,
            decoration: const InputDecoration(
              labelText: 'Correo remitente',
              hintText: 'admin@touchliga.com',
              helperText: 'El correo que verán los participantes como remitente',
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          TextField(
            controller: _fromNameController,
            decoration: const InputDecoration(labelText: 'Nombre remitente', hintText: 'Touchliga'),
          ),
          const SizedBox(height: AppSpacing.xl),

          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: _guardando
                  ? const SizedBox(
                      width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Guardar configuración'),
            ),
          ),
        ],
      ),
    );
  }
}
