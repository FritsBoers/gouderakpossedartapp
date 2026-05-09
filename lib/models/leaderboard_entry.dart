/// Entry in a leaderboard category.
class LeaderboardEntry {
  final String uid;
  final String displayName;
  final String? avatarUrl;
  final dynamic value; // int or double depending on category
  final int rank;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    this.avatarUrl,
    required this.value,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, int rank) {
    return LeaderboardEntry(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? '',
      avatarUrl: map['avatarUrl'],
      value: map['value'] ?? 0,
      rank: rank,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'value': value,
    };
  }
}

/// Leaderboard categories.
enum LeaderboardCategory {
  mostWins,
  highestFinish,
  highestAverage,
  mostGamesPlayed,
  mostLegsWon,
  winRate,
  most180s,
  mostTonPlus,
  checkoutPercentage,
  comebackKing,
  bustKing,
  mostGamesTogether,
}

extension LeaderboardCategoryExtension on LeaderboardCategory {
  String get displayName {
    switch (this) {
      case LeaderboardCategory.mostWins:
        return 'Most Wins';
      case LeaderboardCategory.highestFinish:
        return 'Highest Finish';
      case LeaderboardCategory.highestAverage:
        return 'Highest Avg';
      case LeaderboardCategory.mostGamesPlayed:
        return 'Most Games';
      case LeaderboardCategory.mostLegsWon:
        return 'Most Legs';
      case LeaderboardCategory.winRate:
        return 'Win Rate';
      case LeaderboardCategory.most180s:
        return 'Most 180s';
      case LeaderboardCategory.mostTonPlus:
        return '100+ Scores';
      case LeaderboardCategory.checkoutPercentage:
        return 'Checkout %';
      case LeaderboardCategory.comebackKing:
        return 'Comebacks';
      case LeaderboardCategory.bustKing:
        return 'Bust King';
      case LeaderboardCategory.mostGamesTogether:
        return 'Best Duo';
    }
  }

  String get firestoreField {
    switch (this) {
      case LeaderboardCategory.mostWins:
        return 'totalWins';
      case LeaderboardCategory.highestFinish:
        return 'highestFinish';
      case LeaderboardCategory.highestAverage:
        return 'averageScore';
      case LeaderboardCategory.mostGamesPlayed:
        return 'totalGames';
      case LeaderboardCategory.mostLegsWon:
        return 'totalLegsWon';
      case LeaderboardCategory.most180s:
        return 'total180s';
      case LeaderboardCategory.mostTonPlus:
        return 'totalTonPlus';
      case LeaderboardCategory.comebackKing:
        return 'totalComebacks';
      case LeaderboardCategory.bustKing:
        return 'totalBusts';
      case LeaderboardCategory.winRate:
      case LeaderboardCategory.checkoutPercentage:
      case LeaderboardCategory.mostGamesTogether:
        return ''; // computed client-side
    }
  }

  /// Whether this category is computed client-side from multiple fields.
  bool get isComputed {
    switch (this) {
      case LeaderboardCategory.winRate:
      case LeaderboardCategory.checkoutPercentage:
      case LeaderboardCategory.mostGamesTogether:
        return true;
      default:
        return false;
    }
  }
}
