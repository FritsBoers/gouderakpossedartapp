import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/game_model.dart';

/// Manages game creation, joining, and state synchronization in Firestore.
class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random.secure();

  CollectionReference<Map<String, dynamic>> get _gamesRef =>
      _firestore.collection('games');

  /// Create a new game and return its ID.
  Future<GameModel> createGame({
    required String hostUid,
    required String hostDisplayName,
    int startingScore = 501,
    int legsToWin = 3,
    EntryRule entryRule = EntryRule.straightIn,
    ExitRule exitRule = ExitRule.doubleOut,
    bool isOnline = false,
  }) async {
    final gameCode = await _generateUniqueGameCode();
    final docRef = _gamesRef.doc();

    final game = GameModel(
      id: docRef.id,
      gameCode: gameCode,
      players: [
        GamePlayer(uid: hostUid, displayName: hostDisplayName),
      ],
      playerIds: [hostUid],
      startingScore: startingScore,
      legsToWin: legsToWin,
      entryRule: entryRule,
      exitRule: exitRule,
      status: GameStatus.waiting,
      currentPlayerId: hostUid,
      legs: [
        Leg(
          startingScore: startingScore,
          playerScores: {hostUid: startingScore},
        ),
      ],
      isOnline: isOnline,
      createdAt: DateTime.now(),
    );

    await docRef.set(game.toFirestore());
    return game;
  }

  /// Join an existing game via game code.
  Future<GameModel?> joinGame({
    required String gameCode,
    required String playerUid,
    required String playerDisplayName,
  }) async {
    // Query only on gameCode to avoid needing a composite index
    final querySnapshot = await _gamesRef
        .where('gameCode', isEqualTo: gameCode.toUpperCase())
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    final game = GameModel.fromFirestore(doc);

    // Check status client-side
    if (game.status != GameStatus.waiting) return null;

    // Don't allow joining your own game
    if (game.playerIds.contains(playerUid)) return game;

    final updatedPlayers = [
      ...game.players,
      GamePlayer(uid: playerUid, displayName: playerDisplayName),
    ];
    final updatedPlayerIds = [...game.playerIds, playerUid];

    // Update player scores in current leg
    final updatedLegs = game.legs.map((leg) {
      final scores = Map<String, int>.from(leg.playerScores);
      scores[playerUid] = game.startingScore;
      return leg.copyWith(playerScores: scores);
    }).toList();

    await doc.reference.update({
      'players': updatedPlayers.map((p) => p.toMap()).toList(),
      'playerIds': updatedPlayerIds,
      'legs': updatedLegs.map((l) => l.toMap()).toList(),
    });

    return game.copyWith(
      players: updatedPlayers,
      playerIds: updatedPlayerIds,
      legs: updatedLegs,
    );
  }

  /// Start the game (transition from waiting to inProgress).
  Future<void> startGame(String gameId) async {
    await _gamesRef.doc(gameId).update({
      'status': GameStatus.inProgress.name,
    });
  }

  /// Submit a turn and update game state.
  Future<void> submitTurn({
    required String gameId,
    required Turn turn,
    required int legIndex,
    required int newRemainingScore,
    required bool isBust,
    required bool isLegWon,
    required String? nextPlayerId,
  }) async {
    final docRef = _gamesRef.doc(gameId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final game = GameModel.fromFirestore(snapshot);

      final currentLeg = game.legs[legIndex];
      final updatedTurns = [...currentLeg.turns, turn];

      Map<String, int> updatedScores;
      if (isBust) {
        // Score doesn't change on bust
        updatedScores = currentLeg.playerScores;
      } else {
        updatedScores = Map<String, int>.from(currentLeg.playerScores);
        updatedScores[turn.playerId] = newRemainingScore;
      }

      final updatedLeg = currentLeg.copyWith(
        turns: updatedTurns,
        playerScores: updatedScores,
        winnerId: isLegWon ? turn.playerId : null,
        isComplete: isLegWon,
      );

      final updatedLegs = List<Leg>.from(game.legs);
      updatedLegs[legIndex] = updatedLeg;

      // Update player legs won if leg is complete
      List<GamePlayer> updatedPlayers = game.players;
      if (isLegWon) {
        updatedPlayers = game.players.map((p) {
          if (p.uid == turn.playerId) {
            return p.copyWith(legsWon: p.legsWon + 1);
          }
          return p;
        }).toList();
      }

      // Check if game is won
      final legWinner = updatedPlayers.firstWhere(
        (p) => p.uid == turn.playerId,
      );
      final isGameWon = isLegWon && legWinner.legsWon >= game.legsToWin;

      // If leg is won but game continues, start new leg
      if (isLegWon && !isGameWon) {
        final newLeg = Leg(
          startingScore: game.startingScore,
          playerScores: {
            for (final p in game.players) p.uid: game.startingScore,
          },
        );
        updatedLegs.add(newLeg);
      }

      final updateData = <String, dynamic>{
        'legs': updatedLegs.map((l) => l.toMap()).toList(),
        'players': updatedPlayers.map((p) => p.toMap()).toList(),
        'currentPlayerId': nextPlayerId ?? game.currentPlayerId,
      };

      if (isGameWon) {
        updateData['status'] = GameStatus.completed.name;
        updateData['winnerId'] = turn.playerId;
        updateData['completedAt'] = Timestamp.now();
      }

      transaction.update(docRef, updateData);
    });
  }

  /// Get a game by ID.
  Future<GameModel?> getGame(String gameId) async {
    final doc = await _gamesRef.doc(gameId).get();
    if (!doc.exists) return null;
    return GameModel.fromFirestore(doc);
  }

  /// Stream game updates (for online multiplayer).
  Stream<GameModel?> streamGame(String gameId) {
    return _gamesRef.doc(gameId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameModel.fromFirestore(doc);
    });
  }

  /// Get recent games for a user.
  Future<List<GameModel>> getUserGames(String uid, {int limit = 20}) async {
    final snapshot = await _gamesRef
        .where('playerIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => GameModel.fromFirestore(doc)).toList();
  }

  /// Generate a unique 6-character game code.
  Future<String> _generateUniqueGameCode() async {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No I/O/0/1 to avoid confusion
    String code;
    bool exists;

    do {
      code = List.generate(6, (_) => chars[_random.nextInt(chars.length)]).join();
      final query = await _gamesRef
          .where('gameCode', isEqualTo: code)
          .where('status', whereIn: [GameStatus.waiting.name, GameStatus.inProgress.name])
          .limit(1)
          .get();
      exists = query.docs.isNotEmpty;
    } while (exists);

    return code;
  }
}
