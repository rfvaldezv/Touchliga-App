import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/session_model.dart';
import '../../modules/leagues/models/league_model.dart';

final sessionProvider = StateNotifierProvider<SessionController, SessionModel?>(
  (ref) => SessionController(),
);

class SessionController extends StateNotifier<SessionModel?> {
  SessionController() : super(null);

  void start(SessionModel session) {
    state = session;
  }

  void selectLeague(LeagueModel league) {
    if (state == null) return;

    state = state!.copyWith(activeLeague: league);
  }

  void logout() {
    state = null;
  }
}
