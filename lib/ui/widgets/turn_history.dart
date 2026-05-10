import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';

/// Scrollable list of turns taken in the current leg.
class TurnHistory extends StatelessWidget {
  final List<Turn> turns;
  final List<GamePlayer> players;

  const TurnHistory({super.key, required this.turns, required this.players});

  String _playerName(String playerId) {
    final player = players.where((p) => p.uid == playerId).firstOrNull;
    return player?.displayName ?? playerId;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Turn History',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: turns.isEmpty
                ? const Center(
                    child: Text(
                      'No turns yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    itemCount: turns.length,
                    itemBuilder: (context, index) {
                      final turn = turns[turns.length - 1 - index]; // Newest first
                      return _TurnTile(
                        turn: turn,
                        index: turns.length - index,
                        playerName: _playerName(turn.playerId),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _TurnTile extends StatelessWidget {
  final Turn turn;
  final int index;
  final String playerName;

  const _TurnTile({required this.turn, required this.index, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Turn number
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondaryYellow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '$index',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(width: 12),
          // Player name
          Expanded(
            child: Text(
              playerName,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          // Score
          Text(
            turn.isBust ? 'BUST' : '${turn.totalScore}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: turn.isBust ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
