import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';
import '../../models/user_model.dart';

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
    if (category == LeaderboardCategory.winRate ||
        category == LeaderboardCategory.checkoutPercentage) {
      return '${(entry.value as num).toDouble().toStringAsFixed(1)}%';
    }
    return '${entry.value}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPlayerStats(context, entry),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.rank <= 3
            ? _rankColor.withOpacity(0.1)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: entry.rank <= 3
            ? Border.all(color: _rankColor.withOpacity(0.3))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: entry.rank <= 3
                ? Icon(Icons.emoji_events, color: _rankColor, size: 22)
                : Text(
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
      ),
    );
  }

  static void _showPlayerStats(BuildContext context, LeaderboardEntry entry) {
    // Skip for duo entries (mostGamesTogether uses composite uid)
    if (entry.uid.contains('|')) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PlayerStatsSheet(entry: entry),
    );
  }
}

class _PlayerStatsSheet extends StatefulWidget {
  final LeaderboardEntry entry;
  const _PlayerStatsSheet({required this.entry});

  @override
  State<_PlayerStatsSheet> createState() => _PlayerStatsSheetState();
}

class _PlayerStatsSheetState extends State<_PlayerStatsSheet> {
  PlayerStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.entry.uid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _stats = PlayerStats.fromMap(data['stats'] ?? {});
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Player name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceLight,
                backgroundImage: widget.entry.avatarUrl != null
                    ? NetworkImage(widget.entry.avatarUrl!)
                    : null,
                child: widget.entry.avatarUrl == null
                    ? Text(
                        widget.entry.displayName.isNotEmpty
                            ? widget.entry.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 16),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                widget.entry.displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            )
          else if (_stats == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No stats available', style: TextStyle(color: AppColors.textMuted)),
            )
          else ...[
            _StatLine(label: 'Wins', value: '${_stats!.totalWins}'),
            _StatLine(label: 'Games Played', value: '${_stats!.totalGames}'),
            _StatLine(
              label: 'Win Rate',
              value: _stats!.totalGames > 0
                  ? '${(_stats!.totalWins / _stats!.totalGames * 100).toStringAsFixed(1)}%'
                  : '-',
            ),
            _StatLine(label: 'Legs Won', value: '${_stats!.totalLegsWon}'),
            _StatLine(label: 'Highest Finish', value: '${_stats!.highestFinish}'),
            _StatLine(label: 'Average Score', value: _stats!.averageScore.toStringAsFixed(1)),
            _StatLine(label: '180s', value: '${_stats!.total180s}'),
            _StatLine(label: '100+ Scores', value: '${_stats!.totalTonPlus}'),
            _StatLine(
              label: 'Checkout %',
              value: _stats!.totalCheckoutAttempts > 0
                  ? '${(_stats!.totalCheckouts / _stats!.totalCheckoutAttempts * 100).toStringAsFixed(1)}%'
                  : '-',
            ),
            _StatLine(label: 'Comebacks', value: '${_stats!.totalComebacks}'),
            _StatLine(label: 'Busts', value: '${_stats!.totalBusts}'),
          ],
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  final String label;
  final String value;
  const _StatLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.secondaryYellow,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
