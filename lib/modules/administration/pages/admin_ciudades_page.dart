import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/catalogos_provider.dart';

/// Administración de Ciudades — igual que Estado, necesita país y
/// estado obligatorios, así que tiene su propia pantalla en vez de
/// reutilizar AdminCatalogoPage. El selector de estado se filtra
/// según el país elegido, para no poder mezclar mal los datos.
class AdminCiudadesPage extends ConsumerStatefulWidget {
  const AdminCiudadesPage({super.key});

  @override
  ConsumerState<AdminCiudadesPage> createState() => _AdminCiudadesPageState();
}

class _AdminCiudadesPageState extends ConsumerState<AdminCiudadesPage> {
  List<Map<String, dynamic>> _ciudades = [];
  List<Map<String, dynamic>> _estados = [];
  bool _cargando = true;
  Object? _error;

  final _busquedaController = TextEditingController();
  String _busqueda = '';
  int? _filtroPaisId;
  int? _filtroEstadoId;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final responseCiudades = await ApiClient().getList('/api/ciudads');
      final responseEstados = await ApiClient().getList('/api/estados');
      final ciudades = responseCiudades.data!.cast<Map<String, dynamic>>();
      final estados = responseEstados.data!.cast<Map<String, dynamic>>();
      ciudades.sort((a, b) => (a['nombre'] ?? '').toString().toLowerCase().compareTo((b['nombre'] ?? '').toString().toLowerCase()));
      estados.sort((a, b) => (a['nombre'] ?? '').toString().toLowerCase().compareTo((b['nombre'] ?? '').toString().toLowerCase()));
      if (mounted) {
        setState(() {
          _ciudades = ciudades;
          _estados = estados;
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ciudades'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('No fue posible cargar.\n$_error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
                      child: TextField(
                        controller: _busquedaController,
                        decoration: InputDecoration(
                          hintText: 'Buscar ciudad por nombre...',
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
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          Expanded(
                            child: Consumer(
                              builder: (context, ref, _) {
                                final paisesAsync = ref.watch(paisesProvider);
                                return paisesAsync.when(
                                  loading: () => const LinearProgressIndicator(),
                                  error: (e, _) => const SizedBox.shrink(),
                                  data: (paises) => DropdownButtonFormField<int?>(
                                    initialValue: _filtroPaisId,
                                    decoration: const InputDecoration(
                                      labelText: 'País',
                                      isDense: true,
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: null, child: Text('Todos')),
                                      ...paises.map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre))),
                                    ],
                                    onChanged: (value) => setState(() {
                                      _filtroPaisId = value;
                                      // Si el estado filtrado ya no pertenece
                                      // al pais nuevo, se limpia el filtro.
                                      _filtroEstadoId = null;
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: DropdownButtonFormField<int?>(
                              initialValue: _filtroEstadoId,
                              decoration: const InputDecoration(
                                labelText: 'Estado',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Todos')),
                                ..._estados
                                    .where((e) => _filtroPaisId == null || e['paisId'] == _filtroPaisId)
                                    .map((e) => DropdownMenuItem(
                                          value: e['id'] as int,
                                          child: Text((e['nombre'] ?? '').toString()),
                                        )),
                              ],
                              onChanged: (value) => setState(() => _filtroEstadoId = value),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildLista()),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
    );
  }

  Widget _buildLista() {
    final busquedaNormalizada = _busqueda.trim().toLowerCase();

    final ciudadesFiltradas = _ciudades.where((c) {
      final coincideTexto = busquedaNormalizada.isEmpty ||
          (c['nombre'] ?? '').toString().toLowerCase().contains(busquedaNormalizada);
      final coincidePais = _filtroPaisId == null || c['paisId'] == _filtroPaisId;
      final coincideEstado = _filtroEstadoId == null || c['estadoId'] == _filtroEstadoId;
      return coincideTexto && coincidePais && coincideEstado;
    }).toList();

    if (ciudadesFiltradas.isEmpty) {
      return const Center(child: Text('Ninguna ciudad coincide con el filtro.'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: ciudadesFiltradas.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final ciudad = ciudadesFiltradas[index];
          return Card(
            child: ListTile(
              title: Text((ciudad['nombre'] ?? '').toString()),
              subtitle: Text(
                '${ciudad['estadoNombre'] ?? ''}, ${ciudad['paisNombre'] ?? ''}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showFormDialog(ciudad: ciudad),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmarEliminar(ciudad),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFormDialog({Map<String, dynamic>? ciudad}) async {
    final esNuevo = ciudad == null;

    final codigoController = TextEditingController(text: (ciudad?['codigo'] ?? '').toString());
    final nombreController = TextEditingController(text: (ciudad?['nombre'] ?? '').toString());
    final descripcionController = TextEditingController(text: (ciudad?['descripcion'] ?? '').toString());
    var activo = ciudad?['activo'] as bool? ?? true;
    int? paisIdSeleccionado = ciudad?['paisId'] as int?;
    int? estadoIdSeleccionado = ciudad?['estadoId'] as int?;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            final estadosFiltrados = paisIdSeleccionado == null
                ? <Map<String, dynamic>>[]
                : _estados.where((e) => e['paisId'] == paisIdSeleccionado).toList();

            return AlertDialog(
              title: Text(esNuevo ? 'Nueva ciudad' : 'Editar ciudad'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final paisesAsync = ref.watch(paisesProvider);
                        return paisesAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: LinearProgressIndicator(),
                          ),
                          error: (e, _) => Text('No fue posible cargar países.\n$e'),
                          data: (paises) => DropdownButtonFormField<int>(
                            initialValue: paisIdSeleccionado,
                            decoration: const InputDecoration(labelText: 'País'),
                            items: paises
                                .map((p) => DropdownMenuItem(value: p.id, child: Text(p.nombre)))
                                .toList(),
                            onChanged: (value) => setState(() {
                              paisIdSeleccionado = value;
                              // Si el estado ya elegido no pertenece al pais
                              // nuevo, se limpia para no dejar una combinacion
                              // invalida.
                              estadoIdSeleccionado = null;
                            }),
                          ),
                        );
                      },
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: estadosFiltrados.any((e) => e['id'] == estadoIdSeleccionado)
                          ? estadoIdSeleccionado
                          : null,
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: estadosFiltrados
                          .map<DropdownMenuItem<int>>(
                            (e) => DropdownMenuItem(
                              value: e['id'] as int,
                              child: Text((e['nombre'] ?? '').toString()),
                            ),
                          )
                          .toList(),
                      onChanged: paisIdSeleccionado == null
                          ? null
                          : (value) => setState(() => estadoIdSeleccionado = value),
                    ),
                    if (esNuevo)
                      TextField(
                        controller: codigoController,
                        decoration: const InputDecoration(labelText: 'Código'),
                      ),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo'),
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
                    if (nombreController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('El nombre es obligatorio.')),
                      );
                      return;
                    }
                    if (paisIdSeleccionado == null || estadoIdSeleccionado == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('País y estado son obligatorios.')),
                      );
                      return;
                    }

                    try {
                      if (esNuevo) {
                        await ApiClient().postForValue<int>(
                          '/api/ciudads',
                          body: {
                            'codigo': codigoController.text.trim(),
                            'nombre': nombreController.text.trim(),
                            'descripcion': descripcionController.text.trim(),
                            'paisId': paisIdSeleccionado,
                            'estadoId': estadoIdSeleccionado,
                            'activo': activo,
                          },
                        );
                      } else {
                        await ApiClient().put(
                          '/api/ciudads/${ciudad['id']}',
                          body: {
                            'id': ciudad['id'],
                            'nombre': nombreController.text.trim(),
                            'descripcion': descripcionController.text.trim(),
                            'paisId': paisIdSeleccionado,
                            'estadoId': estadoIdSeleccionado,
                            'activo': activo,
                          },
                        );
                      }

                      await _cargar();

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

  Future<void> _confirmarEliminar(Map<String, dynamic> ciudad) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar ciudad'),
        content: Text(
          '¿Seguro que quieres eliminar "${ciudad['nombre']}"? '
          'Esto no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ApiClient().delete('/api/ciudads/${ciudad['id']}');
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }
}
