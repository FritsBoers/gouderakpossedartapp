import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a darts game.
enum GameStatus { waiting, inProgress, completed, cancelled }

/// Game mode: singles (1v1) or teams (2v2).
enum GameMode { singles, teams }

/// Format: "best of" means you need more than half; "first to" means reach exactly N.
enum GameFormat { bestOf, firstTo }

/// Entry/exit rule.
enum EntryRule { straightIn, doubleIn }
enum ExitRule { straightOut, doubleOut }

/// Represents a single dart throw.
class DartThrow {
  final int score;
  final bool isDouble;
  final bool isTriple;
  final int segment; // 1-20 or 25 (bull)

  const DartThrow({
    required this.score,
    this.isDouble = false,
    this.isTriple = false,
    required this.segment,
  });

  factory DartThrow.fromMap(Map<String, dynamic> map) {
    return DartThrow(
      score: map['score'] ?? 0,
      isDouble: map['isDouble'] ?? false,
      isTriple: map['isTriple'] ?? false,
      segment: map['segment'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'isDouble': isDouble,
      'isTriple': isTriple,
      'segment': segment,
    };
  }
}

/// A turn consists of up to 3 dart throws.
class Turn {
  final String playerId;
  final List<DartThrow> darts;
  final int totalScore;
  final bool isBust;
  final DateTime timestamp;

  const Turn({
    required this.playerId,
    required this.darts,
    required this.totalScore,
    this.isBust = false,
    required this.timestamp,
  });

  factory Turn.fromMap(Map<String, dynamic> map) {
    return Turn(
      playerId: map['playerId'] ?? '',
      darts: (map['darts'] as List<dynamic>?)
              ?.map((d) => DartThrow.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      totalScore: map['totalScore'] ?? 0,
      isBust: map['isBust'] ?? false,
      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'darts': darts.map((d) => d.toMap()).toList(),
      'totalScore': totalScore,
      'isBust': isBust,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// A leg within a game (e.g., first to finish from 501).
class Leg {
  final int startingScore;
  final Map<String, int> playerScores; // playerId → remaining score
  final List<Turn> turns;
  final String? winnerId;
  final bool isComplete;

  const Leg({
    required this.startingScore,
    required this.playerScores,
    this.turns = const [],
    this.winnerId,
    this.isComplete = false,
  });

  factory Leg.fromMap(Map<String, dynamic> map) {
    return Leg(
      startingScore: map['startingScore'] ?? 501,
      playerScores: Map<String, int>.from(map['playerScores'] ?? {}),
      turns: (map['turns'] as List<dynamic>?)
              ?.map((t) => Turn.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      winnerId: map['winnerId'],
      isComplete: map['isComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startingScore': startingScore,
      'playerScores': playerScores,
      'turns': turns.map((t) => t.toMap()).toList(),
      'winnerId': winnerId,
      'isComplete': isComplete,
    };
  }

  Leg copyWith({
    Map<String, int>? playerScores,
    List<Turn>? turns,
    String? winnerId,
    bool? isComplete,
  }) {
    return Leg(
      startingScore: startingScore,
      playerScores: playerScores ?? this.playerScores,
      turns: turns ?? this.turns,
      winnerId: winnerId ?? this.winnerId,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}

/// Player info within a game.
class GamePlayer {
  final String uid;
  final String displayName;
  final int legsWon;
  final int setsWon;

  const GamePlayer({
    required this.uid,
    required this.displayName,
    this.legsWon = 0,
    this.setsWon = 0,
  });

  factory GamePlayer.fromMap(Map<String, dynamic> map) {
    return GamePlayer(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      legsWon: map['legsWon'] ?? 0,
      setsWon: map['setsWon'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'legsWon': legsWon,
      'setsWon': setsWon,
    };
  }

  GamePlayer copyWith({int? legsWon, int? setsWon}) {
    return GamePlayer(
      uid: uid,
      displayName: displayName,
      legsWon: legsWon ?? this.legsWon,
      setsWon: setsWon ?? this.setsWon,
    );
  }
}

/// Represents a full darts game (can contain multiple legs).
class GameModel {
  final String id;
  final String gameCode;
  final List<GamePlayer> players;
  final List<String> playerIds;
  final int startingScore;
  final int legsToWin;
  final int setsToWin; // 0 means no sets (legs only)
  final GameMode gameMode;
  final GameFormat gameFormat;
  final EntryRule entryRule;
  final ExitRule exitRule;
  final List<List<String>>? teams; // team UIDs, e.g. [[uid1,uid2],[uid3,uid4]]
  final GameStatus status;
  final String currentPlayerId;
  final List<Leg> legs;
  final String? winnerId;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime? completedAt;

  const GameModel({
    required this.id,
    required this.gameCode,
    required this.players,
    required this.playerIds,
    this.startingScore = 501,
    this.legsToWin = 3,
    this.setsToWin = 0,
    this.gameMode = GameMode.singles,
    this.gameFormat = GameFormat.bestOf,
    this.entryRule = EntryRule.straightIn,
    this.exitRule = ExitRule.doubleOut,
    this.teams,
    this.status = GameStatus.waiting,
    required this.currentPlayerId,
    this.legs = const [],
    this.winnerId,
    this.isOnline = false,
    required this.createdAt,
    this.completedAt,
  });

  factory GameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GameModel(
      id: doc.id,
      gameCode: data['gameCode'] ?? '',
      players: (data['players'] as List<dynamic>?)
              ?.map((p) => GamePlayer.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      playerIds: List<String>.from(data['playerIds'] ?? []),
      startingScore: data['startingScore'] ?? 501,
      legsToWin: data['legsToWin'] ?? 3,
      setsToWin: data['setsToWin'] ?? 0,
      gameMode: GameMode.values.firstWhere(
        (m) => m.name == data['gameMode'],
        orElse: () => GameMode.singles,
      ),
      gameFormat: GameFormat.values.firstWhere(
        (f) => f.name == data['gameFormat'],
        orElse: () => GameFormat.bestOf,
      ),
      entryRule: EntryRule.values.firstWhere(
        (r) => r.name == data['entryRule'],
        orElse: () => EntryRule.straightIn,
      ),
      exitRule: ExitRule.values.firstWhere(
        (r) => r.name == data['exitRule'],
        orElse: () => ExitRule.doubleOut,
      ),
      teams: (data['teams'] as List<dynamic>?)
              ?.map((t) => List<String>.from(t as List))
              .toList(),
      status: GameStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => GameStatus.waiting,
      ),
      currentPlayerId: data['currentPlayerId'] ?? '',
      legs: (data['legs'] as List<dynamic>?)
              ?.map((l) => Leg.fromMap(l as Map<String, dynamic>))
              .toList() ??
          [],
      winnerId: data['winnerId'],
      isOnline: data['isOnline'] ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gameCode': gameCode,
      'players': players.map((p) => p.toMap()).toList(),
      'playerIds': playerIds,
      'startingScore': startingScore,
      'legsToWin': legsToWin,
      'setsToWin': setsToWin,
      'gameMode': gameMode.name,
      'gameFormat': gameFormat.name,
      'entryRule': entryRule.name,
      'exitRule': exitRule.name,
      'teams': teams,
      'status': status.name,
      'currentPlayerId': currentPlayerId,
      'legs': legs.map((l) => l.toMap()).toList(),
      'winnerId': winnerId,
      'isOnline': isOnline,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  GameModel copyWith({
    List<GamePlayer>? players,
    List<String>? playerIds,
    GameStatus? status,
    String? currentPlayerId,
    List<Leg>? legs,
    String? winnerId,
    DateTime? completedAt,
  }) {
    return GameModel(
      id: id,
      gameCode: gameCode,
      players: players ?? this.players,
      playerIds: playerIds ?? this.playerIds,
      startingScore: startingScore,
      legsToWin: legsToWin,
      setsToWin: setsToWin,
      gameMode: gameMode,
      gameFormat: gameFormat,
      entryRule: entryRule,
      exitRule: exitRule,
      teams: teams,
      status: status ?? this.status,
      currentPlayerId: currentPlayerId ?? this.currentPlayerId,
      legs: legs ?? this.legs,
      winnerId: winnerId ?? this.winnerId,
      isOnline: isOnline,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Helper: get team index for a player (0 or 1), or -1 if not teams mode.
  int teamIndexOf(String playerId) {
    if (teams == null) return -1;
    for (int i = 0; i < teams!.length; i++) {
      if (teams![i].contains(playerId)) return i;
    }
    return -1;
  }
}
