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
