import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/preferences_storage.dart';

/// Liga → Temporada → Jornada que el usuario eligió para navegar.
/// Se guarda en el dispositivo (SharedPreferences) para no tener que
/// volver a elegir cada vez que se abre la app.
class SeleccionState {
  const SeleccionState({
    this.ligaId,
    this.ligaNombre,
    this.temporadaId,
    this.temporadaNombre,
    this.jornadaId,
    this.jornadaNombre,
  });

  final int? ligaId;
  final String? ligaNombre;
  final int? temporadaId;
  final String? temporadaNombre;
  final int? jornadaId;
  final String? jornadaNombre;

  bool get tieneJornadaSeleccionada => jornadaId != null;

  Map<String, dynamic> toJson() => {
    'ligaId': ligaId,
    'ligaNombre': ligaNombre,
    'temporadaId': temporadaId,
    'temporadaNombre': temporadaNombre,
    'jornadaId': jornadaId,
    'jornadaNombre': jornadaNombre,
  };

  factory SeleccionState.fromJson(Map<String, dynamic> json) {
    return SeleccionState(
      ligaId: json['ligaId'] as int?,
      ligaNombre: json['ligaNombre'] as String?,
      temporadaId: json['temporadaId'] as int?,
      temporadaNombre: json['temporadaNombre'] as String?,
      jornadaId: json['jornadaId'] as int?,
      jornadaNombre: json['jornadaNombre'] as String?,
    );
  }
}

class SeleccionNotifier extends StateNotifier<SeleccionState> {
  SeleccionNotifier() : super(_cargarGuardada());

  static const _prefsKey = 'seleccion_liga_temporada_jornada';

  static SeleccionState _cargarGuardada() {
    final json = PreferencesStorage.getJson(_prefsKey);

    if (json == null) return const SeleccionState();

    return SeleccionState.fromJson(json);
  }

  void _guardar() {
    PreferencesStorage.setJson(_prefsKey, state.toJson());
  }

  void elegirLiga(int id, String nombre) {
    // Cambiar de liga invalida la temporada/jornada elegidas antes.
    state = SeleccionState(ligaId: id, ligaNombre: nombre);
    _guardar();
  }

  void elegirTemporada(int id, String nombre) {
    state = SeleccionState(
      ligaId: state.ligaId,
      ligaNombre: state.ligaNombre,
      temporadaId: id,
      temporadaNombre: nombre,
    );
    _guardar();
  }

  void elegirJornada(int id, String nombre) {
    state = SeleccionState(
      ligaId: state.ligaId,
      ligaNombre: state.ligaNombre,
      temporadaId: state.temporadaId,
      temporadaNombre: state.temporadaNombre,
      jornadaId: id,
      jornadaNombre: nombre,
    );
    _guardar();
  }
}

final seleccionProvider = StateNotifierProvider<SeleccionNotifier, SeleccionState>((ref) {
  return SeleccionNotifier();
});
