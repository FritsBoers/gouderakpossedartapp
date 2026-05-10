import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';

/// Displays current scores, legs won, and per-player stats.
class Scoreboard extends StatelessWidget {
  final GameModel game;
  final int currentLegIndex;
  final Map<String, int> topWins;

  const Scoreboard({
    super.key,
    required this.game,
    required this.currentLegIndex,
    this.topWins = const {},
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
                  // Player name with optional medal
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          player.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isActive
                                ? AppColors.secondaryYellow
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (topWins.containsKey(player.uid))
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: topWins[player.uid] == 1
                                ? AppColors.secondaryYellow
                                : topWins[player.uid] == 2
                                    ? const Color(0xFFC0C0C0)
                                    : const Color(0xFFCD7F32),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Remaining score (large)
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Sets & Legs score
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundDark.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        if (game.setsToWin > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.stars, size: 16, color: AppColors.secondaryYellow),
                              const SizedBox(width: 4),
                              Text(
                                'Sets',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${player.setsWon}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                ' / ${game.setsToWin}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flag, size: 16, color: AppColors.secondaryYellow),
                            const SizedBox(width: 4),
                            Text(
                              'Legs',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${player.legsWon}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              ' / ${game.legsToWin}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}
