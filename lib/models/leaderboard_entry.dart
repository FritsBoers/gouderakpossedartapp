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
}

extension LeaderboardCategoryExtension on LeaderboardCategory {
  String get displayName {
    switch (this) {
      case LeaderboardCategory.mostWins:
        return 'Most Wins';
      case LeaderboardCategory.highestFinish:
        return 'Highest Finish';
      case LeaderboardCategory.highestAverage:
        return 'Highest Average';
      case LeaderboardCategory.mostGamesPlayed:
        return 'Most Games';
      case LeaderboardCategory.mostLegsWon:
        return 'Most Legs Won';
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
    }
  }
}
