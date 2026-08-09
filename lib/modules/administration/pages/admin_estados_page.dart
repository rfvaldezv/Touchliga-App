import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/models/catalogo_item_model.dart';
import '../../../shared/providers/catalogos_provider.dart';

/// Administración de Estados — a diferencia de los demás catálogos
/// simples (que reutilizan AdminCatalogoPage), Estado SÍ necesita
/// pedir el País al que pertenece, así que tiene su propia pantalla.
class AdminEstadosPage extends ConsumerStatefulWidget {
  const AdminEstadosPage({super.key});

  @override
  ConsumerState<AdminEstadosPage> createState() => _AdminEstadosPageState();
}

class _AdminEstadosPageState extends ConsumerState<AdminEstadosPage> {
  List<Map<String, dynamic>> _estados = [];
  bool _cargando = true;
  Object? _error;

  final _busquedaController = TextEditingController();
  String _busqueda = '';
  int? _filtroPaisId;

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
      final response = await ApiClient().getList('/api/estados');
      final items = response.data!.cast<Map<String, dynamic>>();
      items.sort((a, b) => (a['nombre'] ?? '').toString().toLowerCase().compareTo((b['nombre'] ?? '').toString().toLowerCase()));
      if (mounted) setState(() { _estados = items; _cargando = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = e; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estados'),
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
                          hintText: 'Buscar estado por nombre...',
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
                              onChanged: (value) => setState(() => _filtroPaisId = value),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(child: _buildLista()),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Widget _buildLista() {
    final busquedaNormalizada = _busqueda.trim().toLowerCase();

    final estadosFiltrados = _estados.where((e) {
      final coincideTexto = busquedaNormalizada.isEmpty ||
          (e['nombre'] ?? '').toString().toLowerCase().contains(busquedaNormalizada);
      final coincidePais = _filtroPaisId == null || e['paisId'] == _filtroPaisId;
      return coincideTexto && coincidePais;
    }).toList();

    if (estadosFiltrados.isEmpty) {
      return const Center(child: Text('Ningún estado coincide con el filtro.'));
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: estadosFiltrados.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final estado = estadosFiltrados[index];
          return Card(
            child: ListTile(
              title: Text((estado['nombre'] ?? '').toString()),
              subtitle: Text((estado['paisNombre'] ?? '').toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showFormDialog(estado: estado),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _confirmarEliminar(estado),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFormDialog({Map<String, dynamic>? estado}) async {
    final esNuevo = estado == null;

    final codigoController = TextEditingController(text: (estado?['codigo'] ?? '').toString());
    final nombreController = TextEditingController(text: (estado?['nombre'] ?? '').toString());
    final descripcionController = TextEditingController(text: (estado?['descripcion'] ?? '').toString());
    var activo = estado?['activo'] as bool? ?? true;
    int? paisIdSeleccionado = estado?['paisId'] as int?;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nuevo estado' : 'Editar estado'),
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
                            onChanged: (value) => setState(() => paisIdSeleccionado = value),
                          ),
                        );
                      },
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
                    if (paisIdSeleccionado == null) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('El país es obligatorio.')),
                      );
                      return;
                    }

                    try {
                      if (esNuevo) {
                        await ApiClient().postForValue<int>(
                          '/api/estados',
                          body: {
                            'codigo': codigoController.text.trim(),
                            'nombre': nombreController.text.trim(),
                            'descripcion': descripcionController.text.trim(),
                            'paisId': paisIdSeleccionado,
                            'activo': activo,
                          },
                        );
                      } else {
                        await ApiClient().put(
                          '/api/estados/${estado['id']}',
                          body: {
                            'id': estado['id'],
                            'nombre': nombreController.text.trim(),
                            'descripcion': descripcionController.text.trim(),
                            'paisId': paisIdSeleccionado,
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

  Future<void> _confirmarEliminar(Map<String, dynamic> estado) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar estado'),
        content: Text(
          '¿Seguro que quieres eliminar "${estado['nombre']}"? '
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
      await ApiClient().delete('/api/estados/${estado['id']}');
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
