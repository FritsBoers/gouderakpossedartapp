import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/leaderboard_entry.dart';
import '../services/leaderboard_service.dart';

/// Provides the LeaderboardService instance.
final leaderboardServiceProvider =
    Provider<LeaderboardService>((ref) => LeaderboardService());

/// Provider for leaderboard data by category.
final leaderboardProvider = FutureProvider.family<List<LeaderboardEntry>, LeaderboardCategory>(
  (ref, category) async {
    final service = ref.read(leaderboardServiceProvider);
    return service.getLeaderboard(category);
  },
);

/// Provider to force refresh a leaderboard category.
final leaderboardRefreshProvider =
    FutureProvider.family<List<LeaderboardEntry>, LeaderboardCategory>(
  (ref, category) async {
    final service = ref.read(leaderboardServiceProvider);
    return service.getLeaderboard(category, forceRefresh: true);
  },
);

/// Top-3 most wins: uid → rank (1, 2, or 3).
final topWinsProvider = FutureProvider<Map<String, int>>((ref) async {
  final entries = await ref.watch(leaderboardProvider(LeaderboardCategory.mostWins).future);
  final map = <String, int>{};
  for (final e in entries) {
    if (e.rank <= 3) map[e.uid] = e.rank;
  }
  return map;
});
