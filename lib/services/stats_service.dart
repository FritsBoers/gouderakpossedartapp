import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/game_model.dart';

/// Computes and updates player statistics after games.
class StatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Update player stats after a game is completed.
  /// If [onlyForPlayer] is set, only that player's stats are updated.
  Future<void> updateStatsAfterGame({
    required GameModel game,
    String? onlyForPlayer,
  }) async {
    if (game.status != GameStatus.completed) return;

    for (final player in game.players) {
      // Skip if we're only updating a specific player
      if (onlyForPlayer != null && player.uid != onlyForPlayer) continue;
      // Skip guest (non-registered) players — no Firestore doc to update
      if (player.uid.startsWith('guest_')) continue;

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
        final game180s = _count180s(game, player.uid);
        final gameTonPlus = _countTonPlus(game, player.uid);
        final gameBusts = _countBusts(game, player.uid);
        final gameCheckouts = _countCheckouts(game, player.uid);
        final gameCheckoutAttempts = _countCheckoutAttempts(game, player.uid);
        final gameComeback = _isComeback(game, player.uid) ? 1 : 0;

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
          total180s: stats.total180s + game180s,
          totalTonPlus: stats.totalTonPlus + gameTonPlus,
          totalBusts: stats.totalBusts + gameBusts,
          totalCheckouts: stats.totalCheckouts + gameCheckouts,
          totalCheckoutAttempts: stats.totalCheckoutAttempts + gameCheckoutAttempts,
          totalComebacks: stats.totalComebacks + gameComeback,
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
        final winningTurns = leg.turns.where((t) => t.playerId == playerId).toList();
        if (winningTurns.isNotEmpty) {
          final lastTurn = winningTurns.last;
          if (lastTurn.totalScore > highest) highest = lastTurn.totalScore;
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

  /// Count 180s scored by a player in a game.
  int _count180s(GameModel game, String playerId) {
    int count = 0;
    for (final leg in game.legs) {
      for (final turn in leg.turns) {
        if (turn.playerId == playerId && !turn.isBust && turn.totalScore == 180) {
          count++;
        }
      }
    }
    return count;
  }

  /// Count 100+ (ton-plus) scores by a player in a game.
  int _countTonPlus(GameModel game, String playerId) {
    int count = 0;
    for (final leg in game.legs) {
      for (final turn in leg.turns) {
        if (turn.playerId == playerId && !turn.isBust && turn.totalScore >= 100) {
          count++;
        }
      }
    }
    return count;
  }

  /// Count busts by a player in a game.
  int _countBusts(GameModel game, String playerId) {
    int count = 0;
    for (final leg in game.legs) {
      for (final turn in leg.turns) {
        if (turn.playerId == playerId && turn.isBust) count++;
      }
    }
    return count;
  }

  /// Count successful checkouts (legs won) by a player.
  int _countCheckouts(GameModel game, String playerId) {
    int count = 0;
    for (final leg in game.legs) {
      if (leg.winnerId == playerId) count++;
    }
    return count;
  }

  /// Count checkout attempts: turns where remaining was <= 170 (reachable finish).
  int _countCheckoutAttempts(GameModel game, String playerId) {
    int count = 0;
    for (final leg in game.legs) {
      final scores = <String, int>{};
      for (final p in game.players) {
        scores[p.uid] = leg.startingScore;
      }
      for (final turn in leg.turns) {
        if (turn.playerId == playerId) {
          final before = scores[playerId] ?? leg.startingScore;
          if (before <= 170) count++;
        }
        if (!turn.isBust) {
          scores[turn.playerId] = (scores[turn.playerId] ?? 0) - turn.totalScore;
        }
      }
    }
    return count;
  }

  /// Check if player won the game after being behind in legs (comeback).
  bool _isComeback(GameModel game, String playerId) {
    if (game.winnerId != playerId) return false;
    final legsWon = <String, int>{};
    for (final p in game.players) {
      legsWon[p.uid] = 0;
    }
    bool wasBehind = false;
    for (final leg in game.legs) {
      if (leg.winnerId != null) {
        legsWon[leg.winnerId!] = (legsWon[leg.winnerId!] ?? 0) + 1;
        final playerLegs = legsWon[playerId] ?? 0;
        final maxOpponentLegs = legsWon.entries
            .where((e) => e.key != playerId)
            .fold(0, (int max, e) => e.value > max ? e.value : max);
        if (maxOpponentLegs > playerLegs) wasBehind = true;
      }
    }
    return wasBehind;
  }
}
