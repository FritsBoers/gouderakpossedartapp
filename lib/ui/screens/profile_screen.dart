import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';
import '../../models/leaderboard_entry.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../widgets/stats_chart.dart';

/// Profile screen showing user info, stats, and account actions.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  Future<void> _editDisplayName(String currentName) async {
    final controller = TextEditingController(text: currentName);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Nickname'),
        content: TextField(
          controller: controller,
          maxLength: 20,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your nickname',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.length >= 3) {
                Navigator.pop(ctx, name);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName != currentName) {
      try {
        await ref.read(authServiceProvider).updateDisplayName(newName);
        ref.read(leaderboardServiceProvider).clearCache();
        ref.invalidate(currentUserProvider);
        for (final cat in LeaderboardCategory.values) {
          ref.invalidate(leaderboardProvider(cat));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nickname updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final stats = ref.watch(playerStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(authServiceProvider).signOut();
              }
            },
          ),
        ],
      ),
      body: currentUser.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not signed in'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppColors.surfaceLight,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 10),
                // Editable nickname
                InkWell(
                  onTap: () => _editDisplayName(user.displayName),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.edit,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  FirebaseAuth.instance.currentUser?.email ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),

                // Badges
                _BadgesSection(uid: user.uid),
                const SizedBox(height: 24),

                // Stats
                stats.when(
                  data: (playerStats) {
                    if (playerStats == null) {
                      return const Text('No stats yet');
                    }
                    return Column(
                      children: [
                        // Charts
                        WinRateChart(stats: playerStats),
                        const SizedBox(height: 32),
                        StatsChart(stats: playerStats),
                        const SizedBox(height: 32),

                        // Stats list
                        Text(
                          'Statistics',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          label: 'Total Wins',
                          value: '${playerStats.totalWins}',
                          icon: Icons.emoji_events,
                        ),
                        _StatRow(
                          label: 'Total Games',
                          value: '${playerStats.totalGames}',
                          icon: Icons.sports_esports,
                        ),
                        _StatRow(
                          label: 'Total Legs Won',
                          value: '${playerStats.totalLegsWon}',
                          icon: Icons.check_circle,
                        ),
                        _StatRow(
                          label: 'Highest Finish',
                          value: '${playerStats.highestFinish}',
                          icon: Icons.arrow_upward,
                        ),
                        _StatRow(
                          label: 'Average Score',
                          value: playerStats.averageScore.toStringAsFixed(1),
                          icon: Icons.analytics,
                        ),
                      ],
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Failed to load stats'),
                ),

                const SizedBox(height: 32),

                // Dev: Reset all games
                TextButton.icon(
                  onPressed: () => _confirmResetGames(context),
                  icon: const Icon(Icons.delete_sweep, color: Colors.orange),
                  label: const Text(
                    'Reset All Game Data',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),

                // Delete account
                TextButton.icon(
                  onPressed: () => _confirmDeleteAccount(context),
                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                  label: const Text(
                    'Delete Account',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Error loading profile')),
      ),
    );
  }

  Future<void> _confirmResetGames(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Games'),
        content: const Text(
          'This will delete ALL game data for every player. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firestore = FirebaseFirestore.instance;
        // Delete all games
        final games = await firestore.collection('games').get();
        // Batch delete in chunks of 500 (Firestore limit)
        for (var i = 0; i < games.docs.length; i += 500) {
          final batch = firestore.batch();
          final chunk = games.docs.skip(i).take(500);
          for (final doc in chunk) {
            batch.delete(doc.reference);
          }
          await batch.commit();
        }

        // Reset all users' stats
        final users = await firestore.collection('users').get();
        for (var i = 0; i < users.docs.length; i += 500) {
          final batch = firestore.batch();
          final chunk = users.docs.skip(i).take(500);
          for (final doc in chunk) {
            batch.update(doc.reference, {'stats': const PlayerStats().toMap()});
          }
          await batch.commit();
        }

        ref.invalidate(currentUserProvider);
        ref.invalidate(playerStatsProvider);
        await ref.read(leaderboardServiceProvider).clearCache();
        for (final cat in LeaderboardCategory.values) {
          ref.invalidate(leaderboardProvider(cat));
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All game data deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to reset: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently delete your account and all associated data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).deleteAccount();
    }
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondaryYellow.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.secondaryYellow, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondaryYellow,
                ),
          ),
        ],
      ),
    );
  }
}

/// Shows badge icons for every leaderboard category where the user is top 3.
class _BadgesSection extends ConsumerWidget {
  final String uid;
  const _BadgesSection({required this.uid});

  static const _badgeCategories = LeaderboardCategory.values;

  static const _rankColors = <int, Color>{
    1: AppColors.secondaryYellow,
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  static const _rankLabels = <int, String>{
    1: '1st',
    2: '2nd',
    3: '3rd',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect badges from all categories
    final badges = <_Badge>[];
    for (final cat in _badgeCategories) {
      final lb = ref.watch(leaderboardProvider(cat));
      lb.whenData((entries) {
        for (final entry in entries) {
          if (entry.uid == uid && entry.rank <= 3) {
            badges.add(_Badge(
              category: cat,
              rank: entry.rank,
            ));
          }
        }
      });
    }

    if (badges.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Text('Badges', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: badges.map((badge) {
            final color = _rankColors[badge.rank] ?? AppColors.textMuted;
            return Tooltip(
              message: '${_rankLabels[badge.rank]} in ${badge.category.displayName}',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: color, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      badge.category.displayName,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Badge {
  final LeaderboardCategory category;
  final int rank;
  const _Badge({required this.category, required this.rank});
}
