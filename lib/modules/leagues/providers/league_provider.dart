import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/league_model.dart';
import '../services/league_service.dart';

final leagueServiceProvider = Provider<LeagueService>((ref) {
  return LeagueService(apiClient: ApiClient());
});

final leaguesProvider = FutureProvider.autoDispose<List<LeagueModel>>((ref) async {
  final service = ref.read(leagueServiceProvider);

  return service.getUserLeagues();
});
