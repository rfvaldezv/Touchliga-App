class WelcomeModel {
  const WelcomeModel({
    required this.userName,
    required this.leagueName,
    required this.tournamentName,
    required this.position,
    required this.points,
  });

  final String userName;
  final String leagueName;
  final String tournamentName;
  final int position;
  final int points;
}
