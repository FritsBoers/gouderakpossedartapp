import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';
import '../../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_table.dart';

/// Provider for community totals across all players.
final communityTotalsProvider = FutureProvider<Map<String, int>>((ref) async {
  final snapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('emailVerified', isEqualTo: true)
      .get();
  int totalGames = 0;
  int totalLegs = 0;
  int total180s = 0;
  int totalTonPlus = 0;
  int totalHighFinishes = 0;

  for (final doc in snapshot.docs) {
    final stats = (doc.data()['stats'] as Map<String, dynamic>?) ?? {};
    totalGames += (stats['totalGames'] ?? 0) as int;
    totalLegs += (stats['totalLegsWon'] ?? 0) as int;
    total180s += (stats['total180s'] ?? 0) as int;
    totalTonPlus += (stats['totalTonPlus'] ?? 0) as int;
    totalHighFinishes += (stats['totalHighFinishes'] ?? 0) as int;
  }

  return {
    'totalGames': totalGames,
    'totalLegs': totalLegs,
    'total180s': total180s,
    'totalTonPlus': totalTonPlus,
    'totalHighFinishes': totalHighFinishes,
  };
});

/// Leaderboard screen with tabs for each category.
class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LeaderboardCategory.values.length + 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.secondaryYellow,
          labelColor: AppColors.secondaryYellow,
          unselectedLabelColor: Colors.white,
          tabs: [
            ...LeaderboardCategory.values
                .map((c) => Tab(text: c.displayName)),
            const Tab(text: 'Totals'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ...LeaderboardCategory.values
              .map((category) => _LeaderboardTab(category: category)),
          const _TotalsTab(),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends ConsumerWidget {
  final LeaderboardCategory category;

  const _LeaderboardTab({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider(category));

    return leaderboard.when(
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Text('No data yet. Play some games!'),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(leaderboardProvider(category));
          },
          child: LeaderboardTableWidget(
            entries: entries,
            category: category,
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load leaderboard',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(leaderboardProvider(category)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalsTab extends ConsumerWidget {
  const _TotalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(communityTotalsProvider);

    return totals.when(
      data: (data) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(communityTotalsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Community Totals',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.secondaryYellow,
                    ),
              ),
              const SizedBox(height: 24),
              _TotalStatCard(
                icon: Icons.sports_score,
                label: 'Games Played',
                value: data['totalGames']!,
              ),
              _TotalStatCard(
                icon: Icons.flag,
                label: 'Legs Played',
                value: data['totalLegs']!,
              ),
              _TotalStatCard(
                icon: Icons.stars,
                label: '180s',
                value: data['total180s']!,
              ),
              _TotalStatCard(
                icon: Icons.whatshot,
                label: '100+ Scores',
                value: data['totalTonPlus']!,
              ),
              _TotalStatCard(
                icon: Icons.emoji_events,
                label: '100+ Finishes',
                value: data['totalHighFinishes']!,
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Failed to load totals',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => ref.invalidate(communityTotalsProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _TotalStatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondaryYellow, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
            ),
            Text(
              '$value',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.secondaryYellow,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
