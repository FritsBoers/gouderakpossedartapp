import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/stats_provider.dart';
import '../widgets/stats_chart.dart';

/// Profile screen showing user info, stats, and account actions.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploading = false;

  Future<void> _pickAndUploadAvatar() async {
    final input = web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*';
    input.click();

    await input.onChange.first;
    final files = input.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0)!;
    if (file.size > 2 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be under 2MB')),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final reader = web.FileReader();
      reader.readAsArrayBuffer(file);
      await reader.onLoadEnd.first;

      final result = reader.result;
      if (result == null) throw Exception('Failed to read file');

      final bytes = (result as dynamic);
      final data = Uint8List.view(bytes as dynamic);

      await ref.read(authServiceProvider).uploadAvatar(data, file.name);
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

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
        ref.invalidate(currentUserProvider);
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
        title: const Text('Profile'),
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
                // Avatar with edit overlay
                GestureDetector(
                  onTap: _isUploading ? null : _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: AppColors.surfaceLight,
                        backgroundImage: user.avatarUrl != null
                            ? NetworkImage(user.avatarUrl!)
                            : null,
                        child: _isUploading
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : user.avatarUrl == null
                                ? Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(fontSize: 36),
                                  )
                                : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.backgroundDark,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Editable nickname
                GestureDetector(
                  onTap: () => _editDisplayName(user.displayName),
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
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

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
