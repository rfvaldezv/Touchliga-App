import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../modules/sponsors/models/patrocinador_model.dart';
import '../../../../modules/sponsors/providers/patrocinador_provider.dart';
import '../../foundation/app_dimensions.dart';

/// Banner de patrocinadores. Si hay más de uno activo, rota
/// automáticamente entre ellos. Si un patrocinador tiene enlace,
/// el banner completo es tocable y abre ese enlace.
///
/// No requiere ningún parámetro: cada instancia consulta por su
/// cuenta los patrocinadores activos (vía Riverpod), así que se
/// puede colocar en cualquier pantalla con `const SponsorBanner()`.
class SponsorBanner extends ConsumerWidget {
  const SponsorBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patrocinadoresAsync = ref.watch(patrocinadoresActivosProvider);

    return patrocinadoresAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (patrocinadores) {
        if (patrocinadores.isEmpty) return const SizedBox.shrink();

        return _SponsorCarousel(patrocinadores: patrocinadores);
      },
    );
  }
}

class _SponsorCarousel extends StatefulWidget {
  const _SponsorCarousel({required this.patrocinadores});

  final List<PatrocinadorModel> patrocinadores;

  @override
  State<_SponsorCarousel> createState() => _SponsorCarouselState();
}

class _SponsorCarouselState extends State<_SponsorCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _paginaActual = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();

    if (widget.patrocinadores.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted || !_controller.hasClients) return;

        _paginaActual = (_paginaActual + 1) % widget.patrocinadores.length;

        _controller.animateToPage(
          _paginaActual,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _abrirEnlace(String? enlaceUrl) async {
    if (enlaceUrl == null || enlaceUrl.isEmpty) return;

    final uri = Uri.tryParse(enlaceUrl);
    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDimensions.sponsorBannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.patrocinadores.length,
        onPageChanged: (index) => _paginaActual = index,
        itemBuilder: (context, index) {
          final patrocinador = widget.patrocinadores[index];

          return GestureDetector(
            onTap: () => _abrirEnlace(patrocinador.enlaceUrl),
            child: Image.network(
              patrocinador.imagenUrl,
              fit: BoxFit.contain,
              width: double.infinity,
              errorBuilder: (context, error, stackTrace) => Center(
                child: Text(patrocinador.nombre),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
