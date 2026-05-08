import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/leaderboard_entry.dart';

/// Manages leaderboard reads with local caching to minimize Firestore reads.
class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const _cachePrefix = 'leaderboard_cache_';
  static const _cacheTimestampPrefix = 'leaderboard_ts_';
  static const _cacheDuration = Duration(minutes: 15);
  static const _leaderboardLimit = 20;

  /// Get leaderboard entries for a category.
  /// Uses local cache if available and fresh.
  Future<List<LeaderboardEntry>> getLeaderboard(
    LeaderboardCategory category, {
    bool forceRefresh = false,
  }) async {
    // Check cache first
    if (!forceRefresh) {
      final cached = await _getCachedLeaderboard(category);
      if (cached != null) return cached;
    }

    // Fetch from Firestore
    final entries = await _fetchLeaderboard(category);

    // Cache the results
    await _cacheLeaderboard(category, entries);

    return entries;
  }

  /// Fetch leaderboard from Firestore by querying user stats.
  Future<List<LeaderboardEntry>> _fetchLeaderboard(
    LeaderboardCategory category,
  ) async {
    final field = 'stats.${category.firestoreField}';

    final snapshot = await _firestore
        .collection('users')
        .orderBy(field, descending: true)
        .limit(_leaderboardLimit)
        .get();

    return snapshot.docs.asMap().entries.map((entry) {
      final index = entry.key;
      final doc = entry.value;
      final data = doc.data();
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      return LeaderboardEntry(
        uid: doc.id,
        displayName: data['displayName'] ?? '',
        avatarUrl: data['avatarUrl'],
        value: stats[category.firestoreField] ?? 0,
        rank: index + 1,
      );
    }).toList();
  }

  /// Get cached leaderboard data if it exists and is fresh.
  Future<List<LeaderboardEntry>?> _getCachedLeaderboard(
    LeaderboardCategory category,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix${category.name}';
    final tsKey = '$_cacheTimestampPrefix${category.name}';

    final timestamp = prefs.getInt(tsKey);
    if (timestamp == null) return null;

    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    if (DateTime.now().difference(cacheTime) > _cacheDuration) return null;

    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;

    final List<dynamic> jsonList = json.decode(jsonStr);
    return jsonList.asMap().entries.map((entry) {
      return LeaderboardEntry.fromMap(
        entry.value as Map<String, dynamic>,
        entry.key + 1,
      );
    }).toList();
  }

  /// Cache leaderboard data locally.
  Future<void> _cacheLeaderboard(
    LeaderboardCategory category,
    List<LeaderboardEntry> entries,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_cachePrefix${category.name}';
    final tsKey = '$_cacheTimestampPrefix${category.name}';

    final jsonStr = json.encode(entries.map((e) => e.toMap()).toList());
    await prefs.setString(key, jsonStr);
    await prefs.setInt(tsKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// Clear all cached leaderboard data.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (final category in LeaderboardCategory.values) {
      await prefs.remove('$_cachePrefix${category.name}');
      await prefs.remove('$_cacheTimestampPrefix${category.name}');
    }
  }
}
