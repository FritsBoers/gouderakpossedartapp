import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';
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
  final _player1Controller = TextEditingController(text: 'Player 1');
  final _player2Controller = TextEditingController(text: 'Player 2');
  int _startingScore = 501;
  int _legsToWin = 3;

  @override
  void dispose() {
    _player1Controller.dispose();
    _player2Controller.dispose();
    super.dispose();
  }

  void _startGame() {
    final players = [
      GamePlayer(uid: 'local_1', displayName: _player1Controller.text.trim()),
      GamePlayer(uid: 'local_2', displayName: _player2Controller.text.trim()),
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
    return Scaffold(
      appBar: AppBar(title: const Text('New Game')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _player1Controller,
              decoration: const InputDecoration(labelText: 'Player 1'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _player2Controller,
              decoration: const InputDecoration(labelText: 'Player 2'),
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
              onPressed: _startGame,
              child: const Text('START GAME'),
            ),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: AppColors.primaryRed.withOpacity(0.2),
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
              padding: const EdgeInsets.all(8),
              color: AppColors.error.withOpacity(0.2),
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
