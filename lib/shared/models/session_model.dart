import '../../modules/leagues/models/league_model.dart';
import '../../modules/login/models/user_model.dart';

class SessionModel {
  const SessionModel({
    required this.user,
    required this.token,
    this.organizationId,
    this.activeLeague,
  });

  final UserModel user;
  final String token;

  final int? organizationId;

  final LeagueModel? activeLeague;

  SessionModel copyWith({
    UserModel? user,
    String? token,
    int? organizationId,
    LeagueModel? activeLeague,
  }) {
    return SessionModel(
      user: user ?? this.user,
      token: token ?? this.token,
      organizationId: organizationId ?? this.organizationId,
      activeLeague: activeLeague ?? this.activeLeague,
    );
  }
}
