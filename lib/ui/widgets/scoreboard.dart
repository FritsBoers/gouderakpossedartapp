import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';

/// Displays current scores and legs won for all players.
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight),
        ),
      ),
      child: Row(
        children: game.players.map((player) {
          final remaining = currentLeg.playerScores[player.uid] ?? 0;
          final isActive = player.uid == game.currentPlayerId;

          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                border: isActive
                    ? Border.all(color: AppColors.secondaryYellow, width: 2)
                    : null,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  // Player name
                  Text(
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
                  const SizedBox(height: 4),
                  // Remaining score (large)
                  Text(
                    '$remaining',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
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
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
