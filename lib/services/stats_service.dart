import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

/// Computes and updates player statistics after games.
class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update player stats after a game is completed.
  Future<void> updateStatsAfterGame({
    required GameModel game,
  }) async {
    if (game.status != GameStatus.completed) return;

    for (final player in game.players) {
      final userRef = _firestore.collection('users').doc(player.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(userRef);
        if (!doc.exists) return;

        final user = UserModel.fromFirestore(doc);
        final stats = user.stats;

        final isWinner = game.winnerId == player.uid;
        final legsWon = player.legsWon;
        final highestFinish = _calculateHighestFinish(game, player.uid);
        final avgScore = _calculateAverageScore(game, player.uid);

        // Compute running average
        final totalTurns = stats.totalGames > 0
            ? (stats.averageScore * stats.totalGames + avgScore) /
                (stats.totalGames + 1)
            : avgScore;

        final updatedStats = PlayerStats(
          totalWins: stats.totalWins + (isWinner ? 1 : 0),
          totalGames: stats.totalGames + 1,
          totalLegsWon: stats.totalLegsWon + legsWon,
          highestFinish: highestFinish > stats.highestFinish
              ? highestFinish
              : stats.highestFinish,
          averageScore: totalTurns,
        );

        transaction.update(userRef, {'stats': updatedStats.toMap()});
      });
    }
  }

  /// Get stats for a specific user.
  Future<PlayerStats?> getPlayerStats(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data() as Map<String, dynamic>;
    return PlayerStats.fromMap(data['stats'] ?? {});
  }

  /// Calculate the highest finishing score in a game for a player.
  int _calculateHighestFinish(GameModel game, String playerId) {
    int highest = 0;

    for (final leg in game.legs) {
      if (leg.winnerId == playerId && leg.turns.isNotEmpty) {
        // Find the last turn by this player (the winning turn)
        final winningTurns = leg.turns
            .where((t) => t.playerId == playerId)
            .toList();

        if (winningTurns.isNotEmpty) {
          final lastTurn = winningTurns.last;
          if (lastTurn.totalScore > highest) {
            highest = lastTurn.totalScore;
          }
        }
      }
    }

    return highest;
  }

  /// Calculate average score per turn for a player in a game.
  double _calculateAverageScore(GameModel game, String playerId) {
    int totalScore = 0;
    int turnCount = 0;

    for (final leg in game.legs) {
      for (final turn in leg.turns) {
        if (turn.playerId == playerId && !turn.isBust) {
          totalScore += turn.totalScore;
          turnCount++;
        }
      }
    }

    if (turnCount == 0) return 0.0;
    return totalScore / turnCount;
  }
}
