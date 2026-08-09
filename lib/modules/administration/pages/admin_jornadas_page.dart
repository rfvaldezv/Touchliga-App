import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/jornada_model.dart';
import '../providers/administration_provider.dart';

class AdminJornadasPage extends ConsumerWidget {
  const AdminJornadasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operación · Jornadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Operación',
            onSelected: (ruta) {
              // Anuncios y Mensajes viven en rutas top-level (también
              // accesibles desde el menú lateral), no bajo /administration —
              // por eso se manejan aparte en vez del patrón general.
              if (ruta == 'anuncios') {
                context.push(AppRouteNames.announcements);
              } else if (ruta == 'mensajes') {
                context.push(AppRouteNames.messages);
              } else {
                context.push('/administration/$ruta');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'ligas',
                child: ListTile(
                  leading: Icon(Icons.emoji_events_outlined),
                  title: Text('Ligas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'detalle-jornada',
                child: ListTile(
                  leading: Icon(Icons.grid_on_outlined),
                  title: Text('Detalle por jornada'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'ranking',
                child: ListTile(
                  leading: Icon(Icons.leaderboard_outlined),
                  title: Text('Ranking'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'temporadas',
                child: ListTile(
                  leading: Icon(Icons.calendar_month_outlined),
                  title: Text('Temporadas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'usuarios',
                child: ListTile(
                  leading: Icon(Icons.group_outlined),
                  title: Text('Participantes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'equipos',
                child: ListTile(
                  leading: Icon(Icons.shield_outlined),
                  title: Text('Equipos'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'canchas',
                child: ListTile(
                  leading: Icon(Icons.stadium_outlined),
                  title: Text('Canchas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'paises',
                child: ListTile(
                  leading: Icon(Icons.public),
                  title: Text('Países'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'estados',
                child: ListTile(
                  leading: Icon(Icons.map_outlined),
                  title: Text('Estados'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'ciudades',
                child: ListTile(
                  leading: Icon(Icons.location_city_outlined),
                  title: Text('Ciudades'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'patrocinadores',
                child: ListTile(
                  leading: Icon(Icons.campaign_outlined),
                  title: Text('Patrocinadores'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'anuncios',
                child: ListTile(
                  leading: Icon(Icons.announcement_outlined),
                  title: Text('Anuncios'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'mensajes',
                child: ListTile(
                  leading: Icon(Icons.chat_bubble_outline),
                  title: Text('Mensajes'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'finanzas',
                child: ListTile(
                  leading: Icon(Icons.account_balance_wallet_outlined),
                  title: Text('Finanzas'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'premios',
                child: ListTile(
                  leading: Icon(Icons.emoji_events_outlined),
                  title: Text('Configurar premios'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: jornadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No fue posible cargar las jornadas.\n$error',
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(jornadasAdminProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return const Center(child: Text('Todavía no hay jornadas creadas.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(jornadasAdminProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: jornadas.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final jornada = jornadas[index];

                return Card(
                  child: ListTile(
                    leading: Icon(
                      jornada.cerrada ? Icons.lock : Icons.lock_open,
                      color: jornada.cerrada ? Colors.grey : Colors.green,
                    ),
                    title: Text(jornada.nombre),
                    subtitle: Text(
                      jornada.cerrada ? 'Cerrada' : 'Abierta para pronósticos',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (accion) {
                        switch (accion) {
                          case 'ver':
                            context.push('/administration/jornadas/${jornada.id}');
                            break;
                          case 'editar':
                            _showEditarJornadaDialog(context, ref, jornada);
                            break;
                          case 'eliminar':
                            _confirmarEliminarJornada(context, ref, jornada);
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'ver', child: Text('Ver partidos')),
                        PopupMenuItem(value: 'editar', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'eliminar',
                          child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                    onTap: () => context.push('/administration/jornadas/${jornada.id}'),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearJornadaDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva jornada'),
      ),
    );
  }

  Future<void> _showCrearJornadaDialog(BuildContext context, WidgetRef ref) async {
    final temporadas = await ref.read(temporadasProvider.future);

    if (temporadas.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primero necesitas crear una temporada.')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    final codigoController = TextEditingController();
    final nombreController = TextEditingController();
    final numeroController = TextEditingController();
    var temporadaId = temporadas.first.id;
    var fechaCierre = DateTime.now().add(const Duration(days: 7));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Nueva jornada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: temporadaId,
                      decoration: const InputDecoration(labelText: 'Temporada'),
                      items: temporadas
                          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => temporadaId = value!),
                    ),
                    TextField(
                      controller: codigoController,
                      decoration: const InputDecoration(labelText: 'Código (ej. J1)'),
                    ),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre (ej. Jornada 1)'),
                    ),
                    TextField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'Número'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de cierre'),
                      subtitle: Text(
                        '${fechaCierre.day}/${fechaCierre.month}/${fechaCierre.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaCierre,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => fechaCierre = picked);
                      },
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
                    final service = ref.read(administrationServiceProvider);

                    await service.crearJornada(
                      temporadaId: temporadaId,
                      codigo: codigoController.text.trim(),
                      nombre: nombreController.text.trim(),
                      descripcion: '',
                      numero: int.tryParse(numeroController.text) ?? 1,
                      fechaCierre: fechaCierre,
                    );

                    ref.invalidate(jornadasAdminProvider);

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
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

  Future<void> _showEditarJornadaDialog(
    BuildContext context,
    WidgetRef ref,
    JornadaModel jornada,
  ) async {
    final nombreController = TextEditingController(text: jornada.nombre);
    final numeroController = TextEditingController(text: jornada.numero.toString());
    var fechaCierre = jornada.fechaCierre;
    var activo = jornada.activo;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Editar jornada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: numeroController,
                      decoration: const InputDecoration(labelText: 'Número'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de cierre'),
                      subtitle: Text(
                        '${fechaCierre.day}/${fechaCierre.month}/${fechaCierre.year}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaCierre,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => fechaCierre = picked);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activa'),
                      value: activo,
                      onChanged: (value) => setState(() => activo = value),
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
                    final service = ref.read(administrationServiceProvider);

                    try {
                      await service.editarJornada(
                        id: jornada.id,
                        nombre: nombreController.text.trim(),
                        descripcion: jornada.descripcion,
                        numero: int.tryParse(numeroController.text) ?? jornada.numero,
                        fechaCierre: fechaCierre,
                        activo: activo,
                      );

                      ref.invalidate(jornadasAdminProvider);

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

  Future<void> _confirmarEliminarJornada(
    BuildContext context,
    WidgetRef ref,
    JornadaModel jornada,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar esta jornada?'),
        content: Text(
          'Se eliminará "${jornada.nombre}" de forma permanente. '
          'Si tiene partidos ya creados, es posible que no se pueda eliminar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ref.read(administrationServiceProvider).eliminarJornada(jornada.id);
      ref.invalidate(jornadasAdminProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }
}
