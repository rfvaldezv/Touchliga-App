import 'dart:math';

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

          // "Activos" de verdad: estatus Activo Y que no sea una cuenta
          // vinculada (una vinculada ya no es una vía de juego por
          // separado -- ver Usuario.EsCuentaVinculada -- así que no debe
          // sumar como un participante más). Se calcula sobre el total
          // sin filtrar, para que el número no cambie según el chip de
          // estatus/búsqueda que se tenga seleccionado.
          final totalActivos = todosLosUsuarios
              .where((u) => u.estatus == 'Activo' && !u.esCuentaVinculada)
              .length;
          final totalUsuarios = todosLosUsuarios.length;

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
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                child: Text(
                  '$totalActivos participante${totalActivos == 1 ? '' : 's'} activo${totalActivos == 1 ? '' : 's'} '
                  '(de $totalUsuarios en total)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
                        if (usuario.parejaNombre != null)
                          usuario.nombreEquipo != null
                              ? '💑 "${usuario.nombreEquipo}" (${usuario.parejaNombre})'
                              : '💑 ${usuario.parejaNombre}',
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
                          icon: const Icon(Icons.more_vert),
                          tooltip: 'Más opciones',
                          onPressed: () => _showMasOpciones(context, ref, usuario),
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

  Future<void> _showAsignarParejaDialog(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    final todos = await ref.read(usuariosProvider.future);
    final candidatos = todos.where((u) => u.id != usuario.id).toList()
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    var seleccionado = usuario.parejaId;
    final nombreEquipoController = TextEditingController(text: usuario.nombreEquipo ?? '');

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Vincular pareja de ${usuario.nombreCompleto}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Solo visual -- no afecta pronósticos, puntos ni el acceso de ninguno de los 2.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int?>(
                      initialValue: seleccionado,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Pareja'),
                      items: [
                        const DropdownMenuItem<int?>(value: null, child: Text('(Ninguna)')),
                        for (final c in candidatos)
                          DropdownMenuItem<int?>(value: c.id, child: Text(c.nombreCompleto)),
                      ],
                      onChanged: (value) => setState(() => seleccionado = value),
                    ),
                    if (seleccionado != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: nombreEquipoController,
                        decoration: const InputDecoration(
                          labelText: 'Apodo del equipo (opcional)',
                          hintText: 'ej. Los Tigres del Amor',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    await ref
                        .read(usuariosServiceProvider)
                        .asignarPareja(
                          usuarioId: usuario.id,
                          parejaId: seleccionado,
                          nombreEquipo: nombreEquipoController.text.trim().isEmpty
                              ? null
                              : nombreEquipoController.text.trim(),
                        );
                    ref.invalidate(usuariosProvider);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
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

  Future<void> _showCredencialAlternaDialog(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    final todos = await ref.read(usuariosProvider.future);
    // No se excluye a quienes ya están vinculados -- puede que sea
    // justo la persona que quieres volver a vincular (para refrescar
    // su correo/contraseña copiados). El backend decide si se
    // permite o no según a quién esté vinculada actualmente.
    final candidatos = todos.where((u) => u.id != usuario.id).toList()
      ..sort((a, b) => a.nombreCompleto.compareTo(b.nombreCompleto));

    UsuarioAdminModel? seleccionado;
    if (usuario.correoAlterna != null) {
      final coincidencia = todos.where((u) => u.correo == usuario.correoAlterna);
      if (coincidencia.isNotEmpty) seleccionado = coincidencia.first;
    }

    var enviando = false;
    String? error;

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Segundo acceso de ${usuario.nombreCompleto}'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Elige a un participante YA REGISTRADO -- entra con su correo y '
                      'contraseña de siempre (nada nuevo que capturar), pero lo lleva '
                      'directo a esta cuenta (mismos pronósticos, mismos puntos). Deja '
                      'de jugar por su cuenta propia.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Autocomplete<UsuarioAdminModel>(
                      initialValue: TextEditingValue(text: seleccionado?.nombreCompleto ?? ''),
                      displayStringForOption: (u) => '${u.nombreCompleto} (${u.correo})',
                      optionsBuilder: (textEditingValue) {
                        final busqueda = textEditingValue.text.trim().toLowerCase();
                        if (busqueda.isEmpty) return candidatos;
                        return candidatos.where(
                          (u) =>
                              u.nombreCompleto.toLowerCase().contains(busqueda) ||
                              u.correo.toLowerCase().contains(busqueda),
                        );
                      },
                      onSelected: (u) => setState(() => seleccionado = u),
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            labelText: 'Buscar participante ya registrado',
                            prefixIcon: Icon(Icons.search),
                          ),
                        );
                      },
                    ),
                    if (seleccionado != null) ...[
                      const SizedBox(height: 4),
                      Chip(
                        avatar: const Icon(Icons.check_circle, size: 16, color: Colors.green),
                        label: Text(seleccionado!.correo),
                        onDeleted: () => setState(() => seleccionado = null),
                      ),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              actions: [
                if (usuario.correoAlterna != null && seleccionado != null)
                  TextButton(
                    onPressed: enviando
                        ? null
                        : () async {
                            setState(() => enviando = true);
                            try {
                              await ref.read(usuariosServiceProvider).desvincularParticipante(
                                    usuarioObjetivoId: usuario.id,
                                    usuarioVinculadoId: seleccionado!.id,
                                  );
                              ref.invalidate(usuariosProvider);
                              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            } catch (e) {
                              setState(() {
                                error = 'No se pudo quitar: $e';
                                enviando = false;
                              });
                            }
                          },
                    child: const Text('Quitar acceso', style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: enviando ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (seleccionado == null) {
                            setState(() => error = 'Elige un participante de la lista.');
                            return;
                          }
                          setState(() {
                            enviando = true;
                            error = null;
                          });
                          try {
                            await ref.read(usuariosServiceProvider).vincularParticipanteExistente(
                                  usuarioObjetivoId: usuario.id,
                                  usuarioAVincularId: seleccionado!.id,
                                );
                            ref.invalidate(usuariosProvider);
                            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                          } catch (e) {
                            setState(() {
                              error = 'No se pudo vincular: $e';
                              enviando = false;
                            });
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Vincular'),
                ),
              ],
            );
          },
        );
      },
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
    final usuarios = ref.read(usuariosProvider).value ?? [];
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
    var mostrarPassword = false;

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(labelText: 'Contraseña temporal'),
                            obscureText: !mostrarPassword,
                          ),
                        ),
                        IconButton(
                          icon: Icon(mostrarPassword ? Icons.visibility_off : Icons.visibility),
                          tooltip: mostrarPassword ? 'Ocultar' : 'Mostrar',
                          onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
                        ),
                        IconButton(
                          icon: const Icon(Icons.casino_outlined),
                          tooltip: 'Generar contraseña',
                          onPressed: () => setState(() {
                            passwordController.text = _generarPasswordAleatoria();
                            mostrarPassword = true;
                          }),
                        ),
                      ],
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

  Future<void> _showMasOpciones(
    BuildContext context,
    WidgetRef ref,
    UsuarioAdminModel usuario,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Antes solo se podía cambiar el estatus (incluida "Baja
              // definitiva") tocando la etiqueta de color junto al nombre
              // en la lista -- sin ningún ícono ni aviso de que fuera
              // tocable, así que no era fácil de encontrar. Se agrega
              // aquí también, como acción explícita del menú.
              ListTile(
                leading: Icon(
                  usuario.activo ? Icons.toggle_off_outlined : Icons.toggle_on_outlined,
                ),
                title: const Text('Cambiar estatus'),
                subtitle: const Text('Activo, inactivo temporal o baja definitiva'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCambiarEstatusDialog(context, ref, usuario);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar información'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showEditarInfoDialog(context, ref, usuario);
                },
              ),
              ListTile(
                leading: const Icon(Icons.admin_panel_settings_outlined),
                title: const Text('Asignar rol'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showAsignarRolDialog(context, ref, usuario);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_outline),
                title: const Text('Vincular pareja'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showAsignarParejaDialog(context, ref, usuario);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.key,
                  color: usuario.correoAlterna != null ? AppColors.secondary : null,
                ),
                title: const Text('Segundo acceso'),
                subtitle: const Text('Mismos pronósticos, mismo lugar en ranking'),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCredencialAlternaDialog(context, ref, usuario);
                },
              ),
            ],
          ),
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
    final passwordController = TextEditingController();

    var paisId = usuario.paisId;
    var estadoId = usuario.estadoId;
    var ciudadId = usuario.ciudadId;
    var mostrarPassword = false;

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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Nueva contraseña (opcional)',
                              helperText: 'Déjala vacía para no cambiarla',
                            ),
                            obscureText: !mostrarPassword,
                          ),
                        ),
                        IconButton(
                          icon: Icon(mostrarPassword ? Icons.visibility_off : Icons.visibility),
                          tooltip: mostrarPassword ? 'Ocultar' : 'Mostrar',
                          onPressed: () => setState(() => mostrarPassword = !mostrarPassword),
                        ),
                        IconButton(
                          icon: const Icon(Icons.casino_outlined),
                          tooltip: 'Generar contraseña',
                          onPressed: () => setState(() {
                            passwordController.text = _generarPasswordAleatoria();
                            mostrarPassword = true;
                          }),
                        ),
                      ],
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

                      String? nuevaPasswordMostrar;
                      if (passwordController.text.trim().isNotEmpty) {
                        nuevaPasswordMostrar = await ref.read(usuariosServiceProvider).restablecerPassword(
                              usuarioId: usuario.id,
                              nuevaPassword: passwordController.text,
                            );
                      }

                      ref.invalidate(usuariosProvider);

                      if (dialogContext.mounted) Navigator.pop(dialogContext);

                      if (nuevaPasswordMostrar != null && context.mounted) {
                        await showDialog<void>(
                          context: context,
                          builder: (confirmContext) => AlertDialog(
                            title: const Text('Contraseña actualizada'),
                            content: SelectableText(
                              'Contraseña nueva de ${usuario.nombreCompleto}:\n\n$nuevaPasswordMostrar\n\n'
                              'Compártesela por WhatsApp o el medio que uses — solo se muestra esta vez.',
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.pop(confirmContext),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                      }
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

  String _generarPasswordAleatoria() {
    const alfabeto = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    final random = Random();
    return List.generate(10, (_) => alfabeto[random.nextInt(alfabeto.length)]).join();
  }
}
