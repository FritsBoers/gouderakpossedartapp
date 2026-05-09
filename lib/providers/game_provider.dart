import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/game_model.dart';
import '../services/game_service.dart';
import '../core/utils/score_validator.dart';

/// Provides the GameService instance.
final gameServiceProvider = Provider<GameService>((ref) => GameService());

/// Stream provider for an online game (real-time updates).
final gameStreamProvider = StreamProvider.family<GameModel?, String>((ref, gameId) {
  final gameService = ref.watch(gameServiceProvider);
  return gameService.streamGame(gameId);
});

/// State for an active local game (not synced to Firestore in real-time).
class ActiveGameState {
  final GameModel? game;
  final int currentLegIndex;
  final bool isProcessing;
  final String? errorMessage;

  const ActiveGameState({
    this.game,
    this.currentLegIndex = 0,
    this.isProcessing = false,
    this.errorMessage,
  });

  ActiveGameState copyWith({
    GameModel? game,
    int? currentLegIndex,
    bool? isProcessing,
    String? errorMessage,
  }) {
    return ActiveGameState(
      game: game ?? this.game,
      currentLegIndex: currentLegIndex ?? this.currentLegIndex,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: errorMessage,
    );
  }
}

/// Manages the active game state (local multiplayer and scoring logic).
class ActiveGameNotifier extends StateNotifier<ActiveGameState> {
  ActiveGameNotifier() : super(const ActiveGameState());

  /// Initialize a new local game.
  void startLocalGame({
    required List<GamePlayer> players,
    int startingScore = 501,
    int legsToWin = 3,
    int setsToWin = 0,
    GameMode gameMode = GameMode.singles,
    GameFormat gameFormat = GameFormat.bestOf,
    EntryRule entryRule = EntryRule.straightIn,
    ExitRule exitRule = ExitRule.doubleOut,
    List<List<String>>? teams,
  }) {
    final playerIds = players.map((p) => p.uid).toList();
    final game = GameModel(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      gameCode: 'LOCAL',
      players: players,
      playerIds: playerIds,
      startingScore: startingScore,
      legsToWin: legsToWin,
      setsToWin: setsToWin,
      gameMode: gameMode,
      gameFormat: gameFormat,
      entryRule: entryRule,
      exitRule: exitRule,
      teams: teams,
      status: GameStatus.inProgress,
      currentPlayerId: players.first.uid,
      legs: [
        Leg(
          startingScore: startingScore,
          playerScores: {for (final p in players) p.uid: startingScore},
        ),
      ],
      createdAt: DateTime.now(),
    );

    state = ActiveGameState(game: game, currentLegIndex: 0);
  }

  /// Load a game from Firestore (for online play).
  void loadGame(GameModel game) {
    state = ActiveGameState(
      game: game,
      currentLegIndex: game.legs.length - 1,
    );
  }

  /// Submit a turn score for the current player.
  /// [turnScore] is the total score for 3 darts.
  /// [lastDartDouble] indicates if the last dart was a double (for checkout).
  void submitTurn({
    required int turnScore,
    required bool lastDartDouble,
    bool firstDartDouble = false,
    List<DartThrow>? darts,
  }) {
    final game = state.game;
    if (game == null || game.status != GameStatus.inProgress) return;

    final currentLeg = game.legs[state.currentLegIndex];
    final playerId = game.currentPlayerId;
    final remaining = currentLeg.playerScores[playerId] ?? 0;

    // Check if player has opened scoring (for double-in rule)
    final hasOpenedScoring = game.entryRule == EntryRule.straightIn ||
        remaining < game.startingScore;

    // Validate the turn
    final validation = ScoreValidator.validateTurn(
      turnScore: turnScore,
      remainingScore: remaining,
      lastDartDouble: lastDartDouble,
      firstDartDouble: firstDartDouble,
      entryRule: game.entryRule,
      exitRule: game.exitRule,
      hasOpenedScoring: hasOpenedScoring,
    );

    if (!validation.isValid) {
      state = state.copyWith(errorMessage: validation.errorMessage);
      return;
    }

    final turn = Turn(
      playerId: playerId,
      darts: darts ?? [],
      totalScore: turnScore,
      isBust: validation.isBust,
      timestamp: DateTime.now(),
    );

    // Update scores
    Map<String, int> updatedScores;
    if (validation.isBust) {
      updatedScores = currentLeg.playerScores;
    } else {
      updatedScores = Map<String, int>.from(currentLeg.playerScores);
      updatedScores[playerId] = remaining - turnScore;
    }

    final updatedTurns = [...currentLeg.turns, turn];
    final isLegWon = validation.isCheckout;

    var updatedLeg = currentLeg.copyWith(
      turns: updatedTurns,
      playerScores: updatedScores,
      winnerId: isLegWon ? playerId : null,
      isComplete: isLegWon,
    );

    var updatedLegs = List<Leg>.from(game.legs);
    updatedLegs[state.currentLegIndex] = updatedLeg;

    // Update player legs won
    var updatedPlayers = game.players;
    if (isLegWon) {
      updatedPlayers = game.players.map((p) {
        if (p.uid == playerId) {
          return p.copyWith(legsWon: p.legsWon + 1);
        }
        return p;
      }).toList();
    }

    // Determine the winning entity (player or team)
    final legWinner = updatedPlayers.firstWhere((p) => p.uid == playerId);

    // In teams mode, count combined legs for the team
    int teamLegsWon = legWinner.legsWon;
    if (game.gameMode == GameMode.teams && game.teams != null) {
      final teamIdx = game.teamIndexOf(playerId);
      if (teamIdx >= 0) {
        teamLegsWon = updatedPlayers
            .where((p) => game.teams![teamIdx].contains(p.uid))
            .fold(0, (sum, p) => sum + p.legsWon);
      }
    }

    bool isSetWon = false;
    bool isGameWon = false;

    if (game.setsToWin > 0) {
      // Sets mode: check if enough legs won for a set
      isSetWon = isLegWon && teamLegsWon >= game.legsToWin;
      if (isSetWon) {
        // Award set and reset legs
        updatedPlayers = updatedPlayers.map((p) {
          if (game.gameMode == GameMode.teams && game.teams != null) {
            final teamIdx = game.teamIndexOf(p.uid);
            final winnerTeamIdx = game.teamIndexOf(playerId);
            if (teamIdx == winnerTeamIdx) {
              return p.copyWith(setsWon: p.setsWon + 1, legsWon: 0);
            }
          } else if (p.uid == playerId) {
            return p.copyWith(setsWon: p.setsWon + 1, legsWon: 0);
          }
          return p.copyWith(legsWon: 0); // Reset legs for all on new set
        }).toList();

        // Check if game is won by sets
        final setWinner = updatedPlayers.firstWhere((p) => p.uid == playerId);
        int teamSetsWon = setWinner.setsWon;
        if (game.gameMode == GameMode.teams && game.teams != null) {
          final teamIdx = game.teamIndexOf(playerId);
          if (teamIdx >= 0) {
            // In teams, setsWon is tracked per-player but identical for teammates
            teamSetsWon = setWinner.setsWon;
          }
        }
        isGameWon = teamSetsWon >= game.setsToWin;
      }
    } else {
      // No sets — game won by legs directly
      isGameWon = isLegWon && teamLegsWon >= game.legsToWin;
    }

    // If leg won but game continues, start new leg
    int newLegIndex = state.currentLegIndex;
    if (isLegWon && !isGameWon) {
      final newLeg = Leg(
        startingScore: game.startingScore,
        playerScores: {for (final p in game.players) p.uid: game.startingScore},
      );
      updatedLegs.add(newLeg);
      newLegIndex = updatedLegs.length - 1;
    }

    // Move to next player
    final currentIndex = game.playerIds.indexOf(playerId);
    final nextPlayerId = isLegWon
        ? game.playerIds.first // Reset to first player on new leg
        : game.playerIds[(currentIndex + 1) % game.playerIds.length];

    // Determine winnerId: in teams mode, use the player who won the last leg
    final updatedGame = game.copyWith(
      players: updatedPlayers,
      legs: updatedLegs,
      currentPlayerId: isGameWon ? playerId : nextPlayerId,
      status: isGameWon ? GameStatus.completed : GameStatus.inProgress,
      winnerId: isGameWon ? playerId : null,
      completedAt: isGameWon ? DateTime.now() : null,
    );

    state = ActiveGameState(
      game: updatedGame,
      currentLegIndex: newLegIndex,
      errorMessage: null,
    );
  }

  /// Undo the last submitted turn.
  void undoLastTurn() {
    final game = state.game;
    if (game == null || game.status != GameStatus.inProgress) return;

    final currentLeg = game.legs[state.currentLegIndex];
    if (currentLeg.turns.isEmpty) return;

    final lastTurn = currentLeg.turns.last;
    final lastPlayerId = lastTurn.playerId;

    // Restore the score
    final updatedScores = Map<String, int>.from(currentLeg.playerScores);
    if (!lastTurn.isBust) {
      updatedScores[lastPlayerId] =
          (updatedScores[lastPlayerId] ?? 0) + lastTurn.totalScore;
    }

    final updatedTurns = List<Turn>.from(currentLeg.turns)..removeLast();

    final updatedLeg = currentLeg.copyWith(
      turns: updatedTurns,
      playerScores: updatedScores,
      winnerId: null,
      isComplete: false,
    );

    var updatedLegs = List<Leg>.from(game.legs);
    updatedLegs[state.currentLegIndex] = updatedLeg;

    final updatedGame = game.copyWith(
      legs: updatedLegs,
      currentPlayerId: lastPlayerId,
    );

    state = ActiveGameState(
      game: updatedGame,
      currentLegIndex: state.currentLegIndex,
      errorMessage: null,
    );
  }

  /// Get the current player's remaining score.
  int get currentRemainingScore {
    final game = state.game;
    if (game == null) return 0;
    final currentLeg = game.legs[state.currentLegIndex];
    return currentLeg.playerScores[game.currentPlayerId] ?? 0;
  }

  /// Clear any error message.
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset game state.
  void resetGame() {
    state = const ActiveGameState();
  }
}

/// Provider for active game state.
final activeGameProvider =
    StateNotifierProvider<ActiveGameNotifier, ActiveGameState>(
  (ref) => ActiveGameNotifier(),
);
