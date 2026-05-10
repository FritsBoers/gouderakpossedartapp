import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';
import '../../providers/leaderboard_provider.dart';
import '../widgets/leaderboard_table.dart';

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
      length: LeaderboardCategory.values.length,
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
          tabs: LeaderboardCategory.values
              .map((c) => Tab(text: c.displayName))
              .toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: LeaderboardCategory.values
            .map((category) => _LeaderboardTab(category: category))
            .toList(),
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
