import 'package:flutter/material.dart';

/// Selector con búsqueda por teclado — en vez de desplazarte por un
/// dropdown largo (equipos, canchas), escribes unas letras y filtra
/// al instante. Mucho más rápido en computadora.
///
/// A propósito NO usa Autocomplete/RawAutocomplete de Flutter: ese
/// widget muestra las opciones en un overlay flotante que, dentro de
/// un AlertDialog en escritorio (mouse), puede chocar con el
/// rastreo del cursor de Flutter y colgar la pantalla. Aquí la
/// lista de opciones aparece dentro del propio formulario, sin
/// overlay, así que es mucho más robusto.
class SelectorBuscable<T> extends StatefulWidget {
  const SelectorBuscable({
    super.key,
    required this.opciones,
    required this.valorActual,
    required this.etiqueta,
    required this.textoDeOpcion,
    required this.onSeleccionado,
    this.iconoDeOpcion,
  });

  final List<T> opciones;
  final T? valorActual;
  final String etiqueta;
  final String Function(T) textoDeOpcion;
  final ValueChanged<T> onSeleccionado;

  /// Ícono opcional a la izquierda de cada opción (ej. escudo de equipo).
  final Widget Function(T)? iconoDeOpcion;

  @override
  State<SelectorBuscable<T>> createState() => _SelectorBuscableState<T>();
}

class _SelectorBuscableState<T> extends State<SelectorBuscable<T>> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _mostrandoOpciones = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.valorActual != null ? widget.textoDeOpcion(widget.valorActual as T) : '',
    );
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _mostrandoOpciones = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<T> get _opcionesFiltradas {
    final buscado = _controller.text.toLowerCase();

    if (buscado.isEmpty) return widget.opciones;

    return widget.opciones
        .where((o) => widget.textoDeOpcion(o).toLowerCase().contains(buscado))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: widget.etiqueta,
            suffixIcon: const Icon(Icons.search, size: 18),
          ),
          onTap: () => setState(() => _mostrandoOpciones = true),
          onChanged: (_) => setState(() => _mostrandoOpciones = true),
        ),
        ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _mostrandoOpciones ? 1.0 : 0.0,
            child: IgnorePointer(
              ignoring: !_mostrandoOpciones,
              child: Container(
              constraints: const BoxConstraints(maxHeight: 180),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _opcionesFiltradas.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Sin resultados', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _opcionesFiltradas.length,
                      itemBuilder: (context, index) {
                        final opcion = _opcionesFiltradas[index];

                        return ListTile(
                          dense: true,
                          leading: widget.iconoDeOpcion?.call(opcion),
                          title: Text(widget.textoDeOpcion(opcion)),
                          onTap: () {
                            _controller.text = widget.textoDeOpcion(opcion);
                            _focusNode.unfocus();
                            setState(() => _mostrandoOpciones = false);
                            widget.onSeleccionado(opcion);
                          },
                        );
                      },
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
