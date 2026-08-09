import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/router/app_route_names.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/app_typography.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../../shared/services/archivo_service.dart';
import '../../equipos/providers/equipo_provider.dart';
import '../../login/providers/auth_provider.dart';
import '../../pagos/providers/pagos_provider.dart';
import '../models/mi_perfil_model.dart';
import '../providers/perfil_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final perfilAsync = ref.watch(miPerfilProvider);
    final temporadaId = ref.watch(seleccionProvider).temporadaId;

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            _AvatarPerfil(fotoUrl: perfilAsync.value?.fotoUrl),
            const SizedBox(height: AppSpacing.md),
            Text(user?.name ?? 'Usuario', style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.xs),
            Text(user?.email ?? '', style: AppTypography.body),

            if (temporadaId != null) ...[
              const SizedBox(height: AppSpacing.lg),
              _MiCuotaCard(temporadaId: temporadaId),
            ],

            const SizedBox(height: AppSpacing.xl),
            const Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Completa tu perfil', style: AppTypography.subtitle),
            ),
            const SizedBox(height: AppSpacing.sm),

            perfilAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: CircularProgressIndicator(),
              ),
              error: (e, _) => Text('No fue posible cargar tu perfil.\n$e'),
              data: (perfil) => _PerfilExtendidoForm(perfil: perfil),
            ),

            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => _mostrarDialogoCambiarPassword(context, ref),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Cambiar contraseña'),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        index: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRouteNames.home);
              break;
            case 1:
              context.go(AppRouteNames.messages);
              break;
            case 2:
              context.go(AppRouteNames.ganadores);
              break;
            case 3:
              context.go(AppRouteNames.misEstadisticas);
              break;
          }
        },
      ),
    );
  }
}

class _PerfilExtendidoForm extends ConsumerStatefulWidget {
  const _PerfilExtendidoForm({required this.perfil});

  final MiPerfilModel perfil;

  @override
  ConsumerState<_PerfilExtendidoForm> createState() => _PerfilExtendidoFormState();
}

class _PerfilExtendidoFormState extends ConsumerState<_PerfilExtendidoForm> {
  late final TextEditingController _nicknameController;
  DateTime? _fechaNacimiento;
  int? _equipoFavoritoId;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.perfil.nickname ?? '');
    _fechaNacimiento = widget.perfil.fechaNacimiento;
    _equipoFavoritoId = widget.perfil.equipoFavoritoId;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equiposAsync = ref.watch(equiposProvider);

    return Column(
      children: [
        TextField(
          controller: _nicknameController,
          decoration: const InputDecoration(labelText: 'Apodo (nickname)'),
        ),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Fecha de nacimiento'),
          subtitle: Text(
            _fechaNacimiento != null
                ? '${_fechaNacimiento!.day}/${_fechaNacimiento!.month}/${_fechaNacimiento!.year}'
                : 'No capturada',
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _fechaNacimiento ?? DateTime(2000),
              firstDate: DateTime(1930),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _fechaNacimiento = picked);
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        equiposAsync.when(
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text('No fue posible cargar los equipos.\n$e'),
          data: (equipos) {
            return DropdownButtonFormField<int>(
              initialValue: _equipoFavoritoId,
              decoration: const InputDecoration(labelText: 'Equipo favorito'),
              items: equipos
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: (e.escudoUrl != null && e.escudoUrl!.isNotEmpty)
                                  ? NetworkImage(e.escudoUrl!)
                                  : null,
                              child: (e.escudoUrl == null || e.escudoUrl!.isEmpty)
                                  ? Text(e.nombre.isNotEmpty ? e.nombre[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 9))
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(e.nombre),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _equipoFavoritoId = value),
            );
          },
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _guardando ? null : _guardar,
            child: Text(_guardando ? 'Guardando...' : 'Guardar'),
          ),
        ),
      ],
    );
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);

    try {
      await ref.read(perfilServiceProvider).actualizarPerfil(
            fechaNacimiento: _fechaNacimiento,
            equipoFavoritoId: _equipoFavoritoId,
            nickname: _nicknameController.text.trim().isEmpty
                ? null
                : _nicknameController.text.trim(),
          );

      ref.invalidate(miPerfilProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _AvatarPerfil extends ConsumerStatefulWidget {
  const _AvatarPerfil({required this.fotoUrl});

  final String? fotoUrl;

  @override
  ConsumerState<_AvatarPerfil> createState() => _AvatarPerfilState();
}

class _AvatarPerfilState extends ConsumerState<_AvatarPerfil> {
  bool _subiendo = false;

  Future<void> _elegirFuente() async {
    final fuente = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de galería'),
                onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (fuente == null) return;

    await _tomarYSubirFoto(fuente);
  }

  Future<void> _tomarYSubirFoto(ImageSource fuente) async {
    final picker = ImagePicker();

    final foto = await picker.pickImage(
      source: fuente,
      maxWidth: 1000,
      imageQuality: 80,
    );

    if (foto == null) return;

    setState(() => _subiendo = true);

    try {
      final bytes = await foto.readAsBytes();
      final url = await ArchivoService().subir(bytes, foto.name);

      await ref.read(perfilServiceProvider).actualizarPerfil(fotoUrl: url);

      ref.invalidate(miPerfilProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la foto: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _subiendo ? null : _elegirFuente,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (widget.fotoUrl != null && widget.fotoUrl!.isNotEmpty)
                ? NetworkImage(widget.fotoUrl!)
                : null,
            child: _subiendo
                ? const CircularProgressIndicator()
                : (widget.fotoUrl == null || widget.fotoUrl!.isEmpty)
                    ? const Icon(Icons.person, size: 40)
                    : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.camera_alt, size: 16, color: AppColors.onSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiCuotaCard extends ConsumerWidget {
  const _MiCuotaCard({required this.temporadaId});

  final int temporadaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagoAsync = ref.watch(miPagoProvider(temporadaId));

    return pagoAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (resumen) {
        if (resumen.cuota <= 0) return const SizedBox.shrink();

        final pagado = resumen.pagoCompleto;

        return Card(
          color: pagado ? Colors.green.shade50 : Colors.orange.shade50,
          child: ListTile(
            leading: Icon(
              pagado ? Icons.check_circle : Icons.pending_outlined,
              color: pagado ? Colors.green : Colors.orange,
            ),
            title: Text(pagado ? 'Cuota pagada' : 'Cuota pendiente'),
            subtitle: pagado
                ? Text('\$${resumen.totalPagado.toStringAsFixed(2)}')
                : Text(
                    resumen.totalPagado > 0
                        ? 'Llevas \$${resumen.totalPagado.toStringAsFixed(2)} de \$${resumen.cuota.toStringAsFixed(2)}'
                        : 'Ve a "Mi pago" en el menú para pagar tu cuota de esta temporada.',
                  ),
          ),
        );
      },
    );
  }
}

Future<void> _mostrarDialogoCambiarPassword(BuildContext context, WidgetRef ref) async {
  final actualController = TextEditingController();
  final nuevaController = TextEditingController();
  final confirmarController = TextEditingController();
  var enviando = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Cambiar contraseña'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: actualController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña actual'),
                  ),
                  TextField(
                    controller: nuevaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña',
                      helperText: 'Mínimo 6 caracteres',
                    ),
                  ),
                  TextField(
                    controller: confirmarController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Confirmar nueva contraseña'),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 8),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: enviando
                    ? null
                    : () async {
                        if (nuevaController.text != confirmarController.text) {
                          setState(() => error = 'Las contraseñas nuevas no coinciden.');
                          return;
                        }
                        if (nuevaController.text.trim().length < 6) {
                          setState(() => error = 'La nueva contraseña debe tener al menos 6 caracteres.');
                          return;
                        }

                        setState(() {
                          enviando = true;
                          error = null;
                        });

                        try {
                          await ApiClient().post(
                            '/api/usuarios/mi-password',
                            body: {
                              'passwordActual': actualController.text,
                              'passwordNueva': nuevaController.text,
                            },
                          );

                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contraseña actualizada.')),
                            );
                          }
                        } catch (e) {
                          setState(() {
                            enviando = false;
                            error = 'No se pudo cambiar: $e';
                          });
                        }
                      },
                child: Text(enviando ? 'Guardando...' : 'Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}
