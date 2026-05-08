import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/user_model.dart';

/// Card widget showing player info and key stats.
class PlayerCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;

  const PlayerCard({super.key, required this.user, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: user.avatarUrl != null
                    ? NetworkImage(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 20),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.stats.totalWins}W / ${user.stats.totalGames}G • Avg: ${user.stats.averageScore.toStringAsFixed(1)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
