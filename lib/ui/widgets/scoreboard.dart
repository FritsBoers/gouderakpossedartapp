import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';

/// Displays current scores, legs won, and per-player stats.
class Scoreboard extends StatelessWidget {
  final GameModel game;
  final int currentLegIndex;

  const Scoreboard({
    super.key,
    required this.game,
    required this.currentLegIndex,
  });

  @override
  Widget build(BuildContext context) {
    final currentLeg = game.legs[currentLegIndex];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: game.players.map((player) {
          final remaining = currentLeg.playerScores[player.uid] ?? 0;
          final isActive = player.uid == game.currentPlayerId;

          // Per-player stats
          final playerTurns =
              currentLeg.turns.where((t) => t.playerId == player.uid).toList();
          final dartCount = playerTurns.length * 3;
          final lastScore =
              playerTurns.isNotEmpty ? playerTurns.last.totalScore : 0;
          final totalScored = playerTurns.fold<int>(
              0, (sum, t) => sum + (t.isBust ? 0 : t.totalScore));
          final avg3Dart = playerTurns.isNotEmpty
              ? (totalScored / playerTurns.length)
              : 0.0;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                border: isActive
                    ? Border.all(color: AppColors.secondaryYellow, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(16),
                color: isActive
                    ? AppColors.secondaryYellow.withOpacity(0.08)
                    : null,
              ),
              child: Column(
                children: [
                  // Player name
                  Text(
                    player.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.secondaryYellow
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Remaining score (large)
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Legs won
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flag, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${player.legsWon}/${game.legsToWin}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Per-player stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _MiniStat(label: 'D', value: '$dartCount'),
                      _MiniStat(label: 'L', value: '$lastScore'),
                      _MiniStat(
                          label: 'Avg',
                          value: avg3Dart.toStringAsFixed(1)),
                    ],
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
