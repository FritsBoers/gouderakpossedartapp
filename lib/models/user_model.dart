import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a user in the application.
class UserModel {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final String email;
  final String provider; // 'google', 'email', or 'guest'
  final bool emailVerified;
  final DateTime createdAt;
  final PlayerStats stats;

  const UserModel({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.email,
    required this.provider,
    required this.emailVerified,
    required this.createdAt,
    required this.stats,
  });

  /// Whether this user is a guest (non-registered) player.
  bool get isGuest => uid.startsWith('guest_');

  /// Create a guest player with a generated UID.
  factory UserModel.guest(String name) {
    return UserModel(
      uid: 'guest_${DateTime.now().microsecondsSinceEpoch}',
      displayName: name,
      email: '',
      provider: 'guest',
      emailVerified: false,
      createdAt: DateTime.now(),
      stats: const PlayerStats(),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      email: data['email'] ?? '',
      provider: data['provider'] ?? 'email',
      emailVerified: data['emailVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      stats: PlayerStats.fromMap(data['stats'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'email': email,
      'provider': provider,
      'emailVerified': emailVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'stats': stats.toMap(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? avatarUrl,
    bool? emailVerified,
    PlayerStats? stats,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email,
      provider: provider,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt,
      stats: stats ?? this.stats,
    );
  }
}

/// Aggregated player statistics.
class PlayerStats {
  final int totalWins;
  final int totalGames;
  final int totalLegsWon;
  final int highestFinish;
  final double averageScore;
  final int total180s;
  final int totalTonPlus;
  final int totalBusts;
  final int totalCheckouts;
  final int totalCheckoutAttempts;
  final int totalComebacks;

  const PlayerStats({
    this.totalWins = 0,
    this.totalGames = 0,
    this.totalLegsWon = 0,
    this.highestFinish = 0,
    this.averageScore = 0.0,
    this.total180s = 0,
    this.totalTonPlus = 0,
    this.totalBusts = 0,
    this.totalCheckouts = 0,
    this.totalCheckoutAttempts = 0,
    this.totalComebacks = 0,
  });

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      totalWins: map['totalWins'] ?? 0,
      totalGames: map['totalGames'] ?? 0,
      totalLegsWon: map['totalLegsWon'] ?? 0,
      highestFinish: map['highestFinish'] ?? 0,
      averageScore: (map['averageScore'] ?? 0.0).toDouble(),
      total180s: map['total180s'] ?? 0,
      totalTonPlus: map['totalTonPlus'] ?? 0,
      totalBusts: map['totalBusts'] ?? 0,
      totalCheckouts: map['totalCheckouts'] ?? 0,
      totalCheckoutAttempts: map['totalCheckoutAttempts'] ?? 0,
      totalComebacks: map['totalComebacks'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalWins': totalWins,
      'totalGames': totalGames,
      'totalLegsWon': totalLegsWon,
      'highestFinish': highestFinish,
      'averageScore': averageScore,
      'total180s': total180s,
      'totalTonPlus': totalTonPlus,
      'totalBusts': totalBusts,
      'totalCheckouts': totalCheckouts,
      'totalCheckoutAttempts': totalCheckoutAttempts,
      'totalComebacks': totalComebacks,
    };
  }

  PlayerStats copyWith({
    int? totalWins,
    int? totalGames,
    int? totalLegsWon,
    int? highestFinish,
    double? averageScore,
    int? total180s,
    int? totalTonPlus,
    int? totalBusts,
    int? totalCheckouts,
    int? totalCheckoutAttempts,
    int? totalComebacks,
  }) {
    return PlayerStats(
      totalWins: totalWins ?? this.totalWins,
      totalGames: totalGames ?? this.totalGames,
      totalLegsWon: totalLegsWon ?? this.totalLegsWon,
      highestFinish: highestFinish ?? this.highestFinish,
      averageScore: averageScore ?? this.averageScore,
      total180s: total180s ?? this.total180s,
      totalTonPlus: totalTonPlus ?? this.totalTonPlus,
      totalBusts: totalBusts ?? this.totalBusts,
      totalCheckouts: totalCheckouts ?? this.totalCheckouts,
      totalCheckoutAttempts: totalCheckoutAttempts ?? this.totalCheckoutAttempts,
      totalComebacks: totalComebacks ?? this.totalComebacks,
    );
  }
}
