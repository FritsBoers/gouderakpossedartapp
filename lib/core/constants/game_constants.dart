/// Game constants for darts scoring.
class GameConstants {
  GameConstants._();

  /// Default starting score for a standard game.
  static const int defaultStartingScore = 501;

  /// Available starting scores.
  static const List<int> startingScores = [301, 501, 701];

  /// Default number of legs to win a match.
  static const int defaultLegsToWin = 3;

  /// Maximum score achievable in one turn (3 x triple 20).
  static const int maxTurnScore = 180;

  /// Maximum checkout score (T20 + T20 + D25).
  static const int maxCheckout = 170;

  /// Minimum checkout score (double 1).
  static const int minCheckout = 2;

  /// Valid single segment values (1-20 + 25 bull).
  static const List<int> segments = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 25,
  ];

  /// All valid scores for a single dart throw.
  static List<int> get validSingleDartScores {
    final scores = <int>{0}; // miss
    for (final segment in segments) {
      scores.add(segment); // single
      if (segment != 25) {
        scores.add(segment * 2); // double
        scores.add(segment * 3); // triple
      } else {
        scores.add(50); // bull (double 25)
      }
    }
    return scores.toList()..sort();
  }

  /// Maximum score for a single dart.
  static const int maxSingleDart = 60; // triple 20

  /// Valid turn totals (all possible 3-dart combinations).
  /// Used for quick input validation.
  static bool isValidTurnScore(int score) {
    return score >= 0 && score <= maxTurnScore;
  }

  /// Scores that cannot be achieved with 3 darts.
  static const List<int> impossibleScores = [179, 178, 176, 175, 173, 172, 169];

  /// Check if a score is a valid 3-dart total.
  static bool isPossibleTurnScore(int score) {
    if (score < 0 || score > maxTurnScore) return false;
    if (impossibleScores.contains(score)) return false;
    return true;
  }
}
