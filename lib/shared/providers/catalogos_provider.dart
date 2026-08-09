import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/catalogo_item_model.dart';
import '../services/catalogo_service.dart';

final paisesProvider = FutureProvider.autoDispose<List<CatalogoItemModel>>((ref) async {
  return CatalogoService(apiClient: ApiClient(), endpoint: '/api/paises').getAll();
});

final estadosProvider = FutureProvider.autoDispose<List<CatalogoItemModel>>((ref) async {
  return CatalogoService(apiClient: ApiClient(), endpoint: '/api/estados').getAll();
});

final ciudadesProvider = FutureProvider.autoDispose<List<CatalogoItemModel>>((ref) async {
  return CatalogoService(apiClient: ApiClient(), endpoint: '/api/ciudads').getAll();
});

final canchasProvider = FutureProvider.autoDispose<List<CatalogoItemModel>>((ref) async {
  return CatalogoService(apiClient: ApiClient(), endpoint: '/api/canchas').getAll();
});
