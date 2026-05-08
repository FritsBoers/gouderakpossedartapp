import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../core/utils/checkout_suggestions.dart';
import '../widgets/score_input.dart';
import '../widgets/scoreboard.dart';
import '../widgets/checkout_suggestion.dart';
import '../widgets/turn_history.dart';

/// Main game screen handling local multiplayer darts.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  bool _showSetup = true;
  UserModel? _player1;
  UserModel? _player2;
  int _startingScore = 501;
  int _legsToWin = 3;

  void _startGame() {
    if (_player1 == null || _player2 == null) return;
    if (_player1!.uid == _player2!.uid) return;

    final players = [
      GamePlayer(uid: _player1!.uid, displayName: _player1!.displayName),
      GamePlayer(uid: _player2!.uid, displayName: _player2!.displayName),
    ];

    ref.read(activeGameProvider.notifier).startLocalGame(
          players: players,
          startingScore: _startingScore,
          legsToWin: _legsToWin,
        );

    setState(() => _showSetup = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSetup) {
      return _buildSetupScreen(context);
    }
    return _buildGameScreen(context);
  }

  Widget _buildSetupScreen(BuildContext context) {
    final allUsers = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Game')),
      body: allUsers.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('No registered players found'));
          }
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Player 1 dropdown
                Text('Player 1', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _player1?.uid,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Select player 1',
                  ),
                  items: users.map((u) => DropdownMenuItem(
                    value: u.uid,
                    child: Text(u.displayName),
                  )).toList(),
                  onChanged: (uid) {
                    setState(() {
                      _player1 = users.firstWhere((u) => u.uid == uid);
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Player 2 dropdown
                Text('Player 2', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _player2?.uid,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Select player 2',
                  ),
                  items: users.map((u) => DropdownMenuItem(
                    value: u.uid,
                    child: Text(u.displayName),
                  )).toList(),
                  onChanged: (uid) {
                    setState(() {
                      _player2 = users.firstWhere((u) => u.uid == uid);
                    });
                  },
                ),
                if (_player1 != null && _player2 != null && _player1!.uid == _player2!.uid)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Please select two different players',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: 24),
                // Starting score selector
                Text('Starting Score', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 301, label: Text('301')),
                    ButtonSegment(value: 501, label: Text('501')),
                    ButtonSegment(value: 701, label: Text('701')),
                  ],
                  selected: {_startingScore},
                  onSelectionChanged: (set) => setState(() => _startingScore = set.first),
                ),
                const SizedBox(height: 24),
                // Legs to win selector
                Text('Legs to Win', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 1, label: Text('1')),
                    ButtonSegment(value: 3, label: Text('3')),
                    ButtonSegment(value: 5, label: Text('5')),
                  ],
                  selected: {_legsToWin},
                  onSelectionChanged: (set) => setState(() => _legsToWin = set.first),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _player1 != null &&
                          _player2 != null &&
                          _player1!.uid != _player2!.uid
                      ? _startGame
                      : null,
                  child: const Text('START GAME'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load players: $e')),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    final gameState = ref.watch(activeGameProvider);
    final game = gameState.game;

    if (game == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game')),
        body: const Center(child: Text('No active game')),
      );
    }

    // Game completed
    if (game.status == GameStatus.completed) {
      return _buildGameOverScreen(context, game);
    }

    final currentLeg = game.legs[gameState.currentLegIndex];
    final currentPlayerId = game.currentPlayerId;
    final currentPlayer = game.players.firstWhere((p) => p.uid == currentPlayerId);
    final remaining = currentLeg.playerScores[currentPlayerId] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leg ${gameState.currentLegIndex + 1}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context, currentLeg),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard
          Scoreboard(game: game, currentLegIndex: gameState.currentLegIndex),

          // Current player indicator
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${currentPlayer.displayName}\'s turn',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.secondaryYellow,
                  ),
            ),
          ),

          // Checkout suggestion
          if (CheckoutSuggestions.canCheckout(remaining))
            CheckoutSuggestionWidget(remaining: remaining),

          // Error message
          if (gameState.errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                gameState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ),

          // Score input
          Expanded(
            child: ScoreInput(
              onScoreSubmitted: (score, isDouble) {
                ref.read(activeGameProvider.notifier).submitTurn(
                      turnScore: score,
                      lastDartDouble: isDouble,
                    );
              },
              remainingScore: remaining,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverScreen(BuildContext context, GameModel game) {
    final winner = game.players.firstWhere((p) => p.uid == game.winnerId);

    return Scaffold(
      appBar: AppBar(title: const Text('Game Over')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: AppColors.secondaryYellow),
              const SizedBox(height: 24),
              Text(
                '${winner.displayName} wins!',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 16),
              ...game.players.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '${p.displayName}: ${p.legsWon} legs',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  ref.read(activeGameProvider.notifier).resetGame();
                  setState(() => _showSetup = true);
                },
                child: const Text('NEW GAME'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('BACK TO HOME'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, Leg currentLeg) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TurnHistory(turns: currentLeg.turns),
    );
  }
}
