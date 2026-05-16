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
    // Computed categories need client-side calculation
    if (category.isComputed) {
      return _fetchComputedLeaderboard(category);
    }

    final field = 'stats.${category.firestoreField}';

    final snapshot = await _firestore
        .collection('users')
        .orderBy(field, descending: true)
        .limit(_leaderboardLimit)
        .get();

    return snapshot.docs.asMap().entries
        .where((entry) => entry.value.data()['emailVerified'] == true)
        .map((entry) {
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

  /// Fetch computed leaderboards (win rate, checkout %, best duo).
  Future<List<LeaderboardEntry>> _fetchComputedLeaderboard(
    LeaderboardCategory category,
  ) async {
    if (category == LeaderboardCategory.mostGamesTogether) {
      return _fetchBestDuo();
    }

    // Fetch all users for computed ratio categories (filter client-side)
    final snapshot = await _firestore.collection('users').get();
    final entries = <LeaderboardEntry>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['emailVerified'] != true) continue;
      final stats = data['stats'] as Map<String, dynamic>? ?? {};

      double value;
      if (category == LeaderboardCategory.winRate) {
        final games = (stats['totalGames'] ?? 0) as int;
        final wins = (stats['totalWins'] ?? 0) as int;
        if (games < 3) continue; // Minimum 3 games for win rate
        value = (wins / games) * 100;
      } else {
        // checkoutPercentage
        final attempts = (stats['totalCheckoutAttempts'] ?? 0) as int;
        final checkouts = (stats['totalCheckouts'] ?? 0) as int;
        if (attempts < 3) continue; // Minimum 3 attempts
        value = (checkouts / attempts) * 100;
      }

      entries.add(LeaderboardEntry(
        uid: doc.id,
        displayName: data['displayName'] ?? '',
        avatarUrl: data['avatarUrl'],
        value: double.parse(value.toStringAsFixed(1)),
        rank: 0,
      ));
    }

    // Sort descending
    entries.sort((a, b) => (b.value as double).compareTo(a.value as double));

    // Assign ranks and limit
    return entries.take(_leaderboardLimit).toList().asMap().entries.map((e) {
      return LeaderboardEntry(
        uid: e.value.uid,
        displayName: e.value.displayName,
        avatarUrl: e.value.avatarUrl,
        value: e.value.value,
        rank: e.key + 1,
      );
    }).toList();
  }

  /// Fetch best duo: find the pair of players who played the most games together.
  Future<List<LeaderboardEntry>> _fetchBestDuo() async {
    final snapshot = await _firestore
        .collection('games')
        .where('status', isEqualTo: 'completed')
        .get();

    // Count games per player pair
    final pairCounts = <String, int>{};
    final pairNames = <String, String>{};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final playerIds = List<String>.from(data['playerIds'] ?? []);
      final players = (data['players'] as List<dynamic>?) ?? [];

      // Build name lookup
      final nameMap = <String, String>{};
      for (final p in players) {
        final pm = p as Map<String, dynamic>;
        nameMap[pm['uid'] ?? ''] = pm['displayName'] ?? '';
      }

      // Count each unique pair
      for (int i = 0; i < playerIds.length; i++) {
        if (playerIds[i].startsWith('guest_')) continue;
        for (int j = i + 1; j < playerIds.length; j++) {
          if (playerIds[j].startsWith('guest_')) continue;
          final ids = [playerIds[i], playerIds[j]]..sort();
          final key = '${ids[0]}|${ids[1]}';
          pairCounts[key] = (pairCounts[key] ?? 0) + 1;
          pairNames[key] = '${nameMap[ids[0]] ?? '?'} & ${nameMap[ids[1]] ?? '?'}';
        }
      }
    }

    // Sort by count descending
    final sorted = pairCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(_leaderboardLimit).toList().asMap().entries.map((e) {
      return LeaderboardEntry(
        uid: e.value.key,
        displayName: pairNames[e.value.key] ?? '?',
        value: e.value.value,
        rank: e.key + 1,
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
