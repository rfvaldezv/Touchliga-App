import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../services/archivo_service.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';

/// Selector de imagen reutilizable: sube el archivo elegido (ya no
/// se pide URL a mano) y avisa la URL resultante por [onCambio].
/// [circular] = true para escudos/logos (avatar redondo);
/// false para banners (caja rectangular, como los de patrocinador).
class SelectorImagenWidget extends StatefulWidget {
  const SelectorImagenWidget({
    super.key,
    required this.urlActual,
    required this.onCambio,
    this.circular = false,
    this.alto = 90,
  });

  final String? urlActual;
  final ValueChanged<String?> onCambio;
  final bool circular;
  final double alto;

  @override
  State<SelectorImagenWidget> createState() => _SelectorImagenWidgetState();
}

class _SelectorImagenWidgetState extends State<SelectorImagenWidget> {
  bool _subiendo = false;

  Future<void> _elegirYSubir() async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    final archivo = resultado?.files.single;
    final bytes = archivo?.bytes;

    if (archivo == null || bytes == null) return;

    setState(() => _subiendo = true);

    try {
      final url = await ArchivoService().subir(bytes, archivo.name);
      widget.onCambio(url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Widget _buildPreview() {
    if (_subiendo) {
      return const Center(
        child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    final tieneImagen = widget.urlActual != null && widget.urlActual!.isNotEmpty;

    if (!tieneImagen) {
      return Icon(
        widget.circular ? Icons.shield_outlined : Icons.image_outlined,
        color: Colors.grey,
        size: widget.circular ? 32 : 28,
      );
    }

    return Image.network(
      widget.urlActual!,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.broken_image_outlined, color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = widget.circular
        ? CircleAvatar(radius: 32, backgroundColor: Colors.grey.shade200, child: _buildPreview())
        : ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: widget.alto,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: _buildPreview(),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        preview,
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _subiendo ? null : _elegirYSubir,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(
                widget.urlActual == null || widget.urlActual!.isEmpty
                    ? 'Subir imagen'
                    : 'Cambiar imagen',
              ),
            ),
            if (widget.urlActual != null && widget.urlActual!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.error),
                tooltip: 'Quitar imagen',
                onPressed: _subiendo ? null : () => widget.onCambio(null),
              ),
          ],
        ),
      ],
    );
  }
}
