import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';

/// Table widget displaying leaderboard entries with rank, name, and value.
class LeaderboardTableWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final LeaderboardCategory category;

  const LeaderboardTableWidget({
    super.key,
    required this.entries,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _LeaderboardRow(entry: entry, category: category);
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final LeaderboardCategory category;

  const _LeaderboardRow({required this.entry, required this.category});

  Color get _rankColor {
    switch (entry.rank) {
      case 1:
        return AppColors.secondaryYellow;
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppColors.textMuted;
    }
  }

  String get _formattedValue {
    if (category == LeaderboardCategory.highestAverage) {
      return (entry.value as num).toDouble().toStringAsFixed(1);
    }
    return '${entry.value}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.rank <= 3
            ? _rankColor.withOpacity(0.1)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: entry.rank <= 3
            ? Border.all(color: _rankColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: _rankColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage:
                entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.displayName.isNotEmpty
                        ? entry.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(fontSize: 14),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              entry.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Value
          Text(
            _formattedValue,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: entry.rank <= 3 ? _rankColor : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
