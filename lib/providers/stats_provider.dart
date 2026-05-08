import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/stats_service.dart';
import 'auth_provider.dart';

/// Provides the StatsService instance.
final statsServiceProvider = Provider<StatsService>((ref) => StatsService());

/// Provider for current user's stats.
final playerStatsProvider = FutureProvider<PlayerStats?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final statsService = ref.read(statsServiceProvider);
  return statsService.getPlayerStats(user.uid);
});
