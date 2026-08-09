import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/api_client.dart';
import '../design_system/tokens/app_spacing.dart';
import '../models/catalogo_item_model.dart';
import '../services/catalogo_service.dart';

/// Pantalla de administración reutilizable para catálogos simples
/// (codigo/nombre/descripcion/activo) — Canchas, Categorías,
/// Árbitros, etc. Evita construir una pantalla de administración
/// distinta para cada catálogo con la misma forma.
class AdminCatalogoPage extends ConsumerStatefulWidget {
  const AdminCatalogoPage({
    super.key,
    required this.titulo,
    required this.endpoint,
  });

  final String titulo;
  final String endpoint;

  @override
  ConsumerState<AdminCatalogoPage> createState() => _AdminCatalogoPageState();
}

class _AdminCatalogoPageState extends ConsumerState<AdminCatalogoPage> {
  late final CatalogoService _service;
  List<CatalogoItemModel> _items = [];
  bool _cargando = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _service = CatalogoService(apiClient: ApiClient(), endpoint: widget.endpoint);
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      final items = await _service.getAll();
      items.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      if (mounted) setState(() { _items = items; _cargando = false; _error = null; });
    } catch (e) {
      if (mounted) setState(() { _error = e; _cargando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.titulo),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('No fue posible cargar.\n$_error'))
              : _items.isEmpty
                  ? const Center(child: Text('Todavía no hay elementos.'))
                  : RefreshIndicator(
                      onRefresh: _cargar,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final item = _items[index];

                          return Card(
                            child: ListTile(
                              title: Text(item.nombre),
                              subtitle: Text(
                                item.descripcion.isNotEmpty ? item.descripcion : item.codigo,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                onPressed: () => _showFormDialog(item: item),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
    );
  }

  Future<void> _showFormDialog({CatalogoItemModel? item}) async {
    final esNuevo = item == null;

    final codigoController = TextEditingController(text: item?.codigo ?? '');
    final nombreController = TextEditingController(text: item?.nombre ?? '');
    final descripcionController = TextEditingController(text: item?.descripcion ?? '');
    var activo = item?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nuevo' : 'Editar'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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

                    try {
                      if (esNuevo) {
                        await _service.crear(
                          codigo: codigoController.text.trim(),
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          activo: activo,
                        );
                      } else {
                        await _service.actualizar(
                          id: item.id,
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          activo: activo,
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
}
