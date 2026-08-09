class CurrentRoundModel {
  const CurrentRoundModel({
    required this.round,
    required this.totalMatches,
    required this.completedMatches,
    required this.pendingMatches,
  });

  final int round;
  final int totalMatches;
  final int completedMatches;
  final int pendingMatches;

  double get progress =>
      totalMatches == 0 ? 0 : completedMatches / totalMatches;
}
