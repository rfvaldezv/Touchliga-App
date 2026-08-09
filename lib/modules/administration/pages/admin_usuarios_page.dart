import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/catalogos_provider.dart';
import '../models/usuario_admin_model.dart';
import '../providers/usuarios_provider.dart';

class AdminUsuariosPage extends ConsumerStatefulWidget {
  const AdminUsuariosPage({super.key});

  @override
  ConsumerState<AdminUsuariosPage> createState() => _AdminUsuariosPageState();
}

class _AdminUsuariosPageState extends ConsumerState<AdminUsuariosPage> {
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  String? _filtroEstatus; // null = todos

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuariosAsync = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Participantes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.administration),
        ),
      ),
      body: usuariosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los usuarios.\n$e')),
        data: (todosLosUsuarios) {
          final busquedaNormalizada = _busqueda.trim().toLowerCase();

          final usuarios = todosLosUsuarios.where((u) {
            final coincideTexto = busquedaNormalizada.isEmpty ||
                u.nombreCompleto.toLowerCase().contains(busquedaNormalizada);
            final coincideEstatus = _filtroEstatus == null || u.estatus == _filtroEstatus;
            return coincideTexto && coincideEstatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                child: TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o apellidos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _busquedaController.clear();
                              _busqueda = '';
                            }),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _busqueda = value),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: _filtroEstatus == null,
                        onSelected: (_) => setState(() => _filtroEstatus = null),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Activo'),
                        selected: _filtroEstatus == 'Activo',
                        onSelected: (_) => setState(() => _filtroEstatus = 'Activo'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Inactivo temporal'),
                        selected: _filtroEstatus == 'InactivoTemporal',
                        onSelected: (_) => setState(() => _filtroEstatus = 'InactivoTemporal'),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Baja definitiva'),
                        selected: _filtroEstatus == 'BajaDefinitiva',
                        onSelected: (_) => setState(() => _filtroEstatus = 'BajaDefinitiva'),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: usuarios.isEmpty
                    ? const Center(child: Text('Ningún participante coincide con el filtro.'))
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(usuariosProvider),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: usuarios.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            final usuario = usuarios[index];

                return Card(
                  child: ListTile(
                    title: Text(usuario.nombreCompleto),
                    subtitle: Text(
                      [
                        usuario.correo,
                        if (usuario.ciudadNombre != null) usuario.ciudadNombre!,
                        if (usuario.invitadoPorNombre != null) 'Invitó: ${usuario.invitadoPorNombre}',
                      ].join(' · '),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        GestureDetector(
                          onTap: () => _showCambiarEstatusDialog(context, ref, usuario),
                          child: Chip(
                            label: Text(
                              usuario.estatus,
                              style: TextStyle(
                                color: usuario.activo ? AppColors.onPrimary : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: usuario.activo ? AppColors.secondary : Colors.grey.shade600,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        for (final rol in usuario.roles)
                          Chip(
                            label: Text(
                              rol,
                              style: const TextStyle(
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            backgroundColor: AppColors.primary,
                            visualDensity: VisualDensity.compact,
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Editar información',
                          onPressed: () => _showEditarInfoDialog(context, ref, usuario),
                        ),
                        IconButton(
                          icon: const Icon(Icons.admin_panel_settings_outlined),
                          tooltip: 'Asignar rol',
                          onPressed: () => _showAsignarRolDialog(context, ref, usuario),
                        ),
                      ],
                    ),
                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearUsuarioDialog(context, ref),
        icon: const Icon(Icons.person_add),
        label: const Text('Nuevo participante'),
      ),
    );
  }

  Future<void> _showAsignarRolDialog(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    final roles = await ref.read(rolesProvider.future);

    if (roles.isEmpty || !context.mounted) return;

    var rolId = roles.first.id;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Asignar rol a ${usuario.nombreCompleto}'),
              content: DropdownButtonFormField<int>(
                initialValue: rolId,
                items: roles
                    .map((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre)))
                    .toList(),
                onChanged: (value) => setState(() => rolId = value!),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final service = ref.read(usuariosServiceProvider);
                    await service.asignarRol(usuarioId: usuario.id, rolId: rolId);
                    ref.invalidate(usuariosProvider);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Asignar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCrearUsuarioDialog(BuildContext context, WidgetRef ref) async {
    final usuarios = await ref.read(usuariosProvider.future);
    final paises = await ref.read(paisesProvider.future);
    final estados = await ref.read(estadosProvider.future);
    final ciudades = await ref.read(ciudadesProvider.future);

    if (!context.mounted) return;

    if (paises.isEmpty || estados.isEmpty || ciudades.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Primero necesitas capturar al menos un país, estado y ciudad.'),
        ),
      );
      return;
    }

    final nombreController = TextEditingController();
    final apellidosController = TextEditingController();
    final telefonoController = TextEditingController();
    final correoController = TextEditingController();
    final passwordController = TextEditingController();

    var invitadoPorId = usuarios.isNotEmpty ? usuarios.first.id : 0;
    var paisId = paises.first.id;
    var estadoId = estados.first.id;
    var ciudadId = ciudades.first.id;
    var sexo = 'M';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Nuevo participante'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre(s)'),
                    ),
                    TextField(
                      controller: apellidosController,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                    ),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)'),
                      keyboardType: TextInputType.phone,
                    ),
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(labelText: 'Correo'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Contraseña temporal'),
                      obscureText: true,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: sexo,
                      decoration: const InputDecoration(labelText: 'Sexo'),
                      items: const [
                        DropdownMenuItem(value: 'M', child: Text('Masculino')),
                        DropdownMenuItem(value: 'F', child: Text('Femenino')),
                        DropdownMenuItem(value: 'O', child: Text('Otro')),
                      ],
                      onChanged: (value) => setState(() => sexo = value!),
                    ),
                    if (usuarios.isNotEmpty)
                      DropdownButtonFormField<int>(
                        initialValue: invitadoPorId,
                        decoration: const InputDecoration(labelText: '¿Quién lo invitó?'),
                        items: usuarios
                            .map((u) => DropdownMenuItem(value: u.id, child: Text(u.nombreCompleto)))
                            .toList(),
                        onChanged: (value) => setState(() => invitadoPorId = value!),
                      ),
                    DropdownButtonFormField<int>(
                      initialValue: paisId,
                      decoration: const InputDecoration(labelText: 'País'),
                      items: paises
                          .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => paisId = value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: estadoId,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: estados
                          .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => estadoId = value!),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: ciudadId,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                      items: ciudades
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => ciudadId = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty ||
                        apellidosController.text.trim().isEmpty ||
                        telefonoController.text.trim().isEmpty ||
                        correoController.text.trim().isEmpty ||
                        passwordController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Todos los campos son obligatorios.')),
                      );
                      return;
                    }

                    final service = ref.read(usuariosServiceProvider);

                    try {
                      await service.crearUsuario(
                        nombre: nombreController.text.trim(),
                        apellidos: apellidosController.text.trim(),
                        telefono: telefonoController.text.trim(),
                        correo: correoController.text.trim(),
                        password: passwordController.text.trim(),
                        sexo: sexo,
                        invitadoPorId: invitadoPorId,
                        ciudadId: ciudadId,
                        paisId: paisId,
                        estadoId: estadoId,
                      );

                      ref.invalidate(usuariosProvider);

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo crear: $e')),
                      );
                    }
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditarInfoDialog(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    final paises = await ref.read(paisesProvider.future);
    final estados = await ref.read(estadosProvider.future);
    final ciudades = await ref.read(ciudadesProvider.future);

    if (!context.mounted) return;

    final nombreController = TextEditingController(text: usuario.nombre);
    final apellidosController = TextEditingController(text: usuario.apellidos);
    final telefonoController = TextEditingController(text: usuario.telefono);
    final correoController = TextEditingController(text: usuario.correo);

    var paisId = usuario.paisId;
    var estadoId = usuario.estadoId;
    var ciudadId = usuario.ciudadId;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Editar información de ${usuario.nombreCompleto}'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre(s)'),
                    ),
                    TextField(
                      controller: apellidosController,
                      decoration: const InputDecoration(labelText: 'Apellidos'),
                    ),
                    TextField(
                      controller: correoController,
                      decoration: const InputDecoration(
                        labelText: 'Correo (usuario de acceso)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        icon: const Icon(Icons.lock_reset, size: 18),
                        label: const Text('Restablecer contraseña'),
                        onPressed: () => _confirmarRestablecerPassword(dialogContext, ref, usuario),
                      ),
                    ),
                    TextField(
                      controller: telefonoController,
                      decoration: const InputDecoration(labelText: 'Teléfono (WhatsApp)'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: paises.any((p) => p.id == paisId) ? paisId : null,
                      decoration: const InputDecoration(labelText: 'País'),
                      items: paises.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))).toList(),
                      onChanged: (value) => setState(() => paisId = value),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: estados.any((e) => e.id == estadoId) ? estadoId : null,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: estados.map((e) => DropdownMenuItem(value: e.id, child: Text(e.nombre))).toList(),
                      onChanged: (value) => setState(() => estadoId = value),
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: ciudades.any((c) => c.id == ciudadId) ? ciudadId : null,
                      decoration: const InputDecoration(labelText: 'Ciudad'),
                      items: ciudades.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nombre))).toList(),
                      onChanged: (value) => setState(() => ciudadId = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty || apellidosController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Nombre y apellidos son obligatorios.')),
                      );
                      return;
                    }

                    try {
                      await ref.read(usuariosServiceProvider).editarInfo(
                            usuarioId: usuario.id,
                            nombre: nombreController.text.trim(),
                            apellidos: apellidosController.text.trim(),
                            telefono: telefonoController.text.trim(),
                            correo: correoController.text.trim(),
                            ciudadId: ciudadId,
                            paisId: paisId,
                            estadoId: estadoId,
                          );

                      ref.invalidate(usuariosProvider);

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo guardar: $e')),
                      );
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCambiarEstatusDialog(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    const opciones = [
      (1, 'Activo', 'Participa normal en la quiniela'),
      (2, 'Inactivo temporal', 'No participa por ahora, puede regresar'),
      (3, 'Baja definitiva', 'Ya no participa, se queda como referencia histórica'),
    ];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Estatus de ${usuario.nombreCompleto}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: opciones.map((o) {
              final (valor, etiqueta, descripcion) = o;
              return RadioListTile<int>(
                value: valor,
                groupValue: switch (usuario.estatus) {
                  'InactivoTemporal' => 2,
                  'BajaDefinitiva' => 3,
                  _ => 1,
                },
                title: Text(etiqueta),
                subtitle: Text(descripcion, style: const TextStyle(fontSize: 12)),
                onChanged: (nuevoValor) async {
                  if (nuevoValor == null) return;
                  try {
                    await ref.read(usuariosServiceProvider).cambiarEstatus(
                          usuarioId: usuario.id,
                          estatus: nuevoValor,
                        );
                    ref.invalidate(usuariosProvider);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo cambiar: $e')),
                      );
                    }
                  }
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmarRestablecerPassword(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer contraseña'),
        content: Text(
          'Se va a generar una contraseña temporal nueva para ${usuario.nombreCompleto}. '
          'Su contraseña actual dejará de funcionar. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!context.mounted) return;

    try {
      final nuevaPassword = await ref.read(usuariosServiceProvider).restablecerPassword(usuarioId: usuario.id);

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Nueva contraseña generada'),
          content: SelectableText(
            'Contraseña temporal de ${usuario.nombreCompleto}:\n\n$nuevaPassword\n\n'
            'Compártesela por WhatsApp o el medio que uses — solo se muestra esta vez, '
            'no queda guardada en ningún lado para volver a verla.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo restablecer: $e')),
        );
      }
    }
  }
}
