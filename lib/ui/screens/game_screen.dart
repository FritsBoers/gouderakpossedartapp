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
  GameMode _gameMode = GameMode.singles;
  // Singles players
  UserModel? _player1;
  UserModel? _player2;
  // Teams players
  UserModel? _team1Player1;
  UserModel? _team1Player2;
  UserModel? _team2Player1;
  UserModel? _team2Player2;
  int _startingScore = 501;
  GameFormat _gameFormat = GameFormat.bestOf;
  int _legsCount = 3;
  int _setsCount = 0; // 0 = no sets
  EntryRule _entryRule = EntryRule.straightIn;
  ExitRule _exitRule = ExitRule.doubleOut;

  List<UserModel> get _selectedTeamPlayers => [
        _team1Player1,
        _team1Player2,
        _team2Player1,
        _team2Player2,
      ].whereType<UserModel>().toList();

  bool get _hasDuplicateTeamPlayers {
    final uids = _selectedTeamPlayers.map((u) => u.uid).toList();
    return uids.length != uids.toSet().length;
  }

  void _startGame() {
    List<GamePlayer> players;
    List<List<String>>? teams;

    if (_gameMode == GameMode.singles) {
      if (_player1 == null || _player2 == null) return;
      if (_player1!.uid == _player2!.uid) return;
      players = [
        GamePlayer(uid: _player1!.uid, displayName: _player1!.displayName),
        GamePlayer(uid: _player2!.uid, displayName: _player2!.displayName),
      ];
    } else {
      if (_team1Player1 == null ||
          _team1Player2 == null ||
          _team2Player1 == null ||
          _team2Player2 == null) return;
      if (_hasDuplicateTeamPlayers) return;
      // Players alternate: T1P1, T2P1, T1P2, T2P2
      players = [
        GamePlayer(uid: _team1Player1!.uid, displayName: _team1Player1!.displayName),
        GamePlayer(uid: _team2Player1!.uid, displayName: _team2Player1!.displayName),
        GamePlayer(uid: _team1Player2!.uid, displayName: _team1Player2!.displayName),
        GamePlayer(uid: _team2Player2!.uid, displayName: _team2Player2!.displayName),
      ];
      teams = [
        [_team1Player1!.uid, _team1Player2!.uid],
        [_team2Player1!.uid, _team2Player2!.uid],
      ];
    }

    // Calculate actual legsToWin based on format
    final legsToWin = _gameFormat == GameFormat.bestOf
        ? (_legsCount ~/ 2) + 1 // best of 5 → need 3
        : _legsCount; // first to 3 → need 3

    final setsToWin = _setsCount == 0
        ? 0
        : _gameFormat == GameFormat.bestOf
            ? (_setsCount ~/ 2) + 1
            : _setsCount;

    ref.read(activeGameProvider.notifier).startLocalGame(
          players: players,
          startingScore: _startingScore,
          legsToWin: legsToWin,
          setsToWin: setsToWin,
          gameMode: _gameMode,
          gameFormat: _gameFormat,
          entryRule: _entryRule,
          exitRule: _exitRule,
          teams: teams,
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Game mode
                Text('Game Mode', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<GameMode>(
                  segments: const [
                    ButtonSegment(value: GameMode.singles, label: Text('Singles')),
                    ButtonSegment(value: GameMode.teams, label: Text('Teams 2v2')),
                  ],
                  selected: {_gameMode},
                  onSelectionChanged: (set) => setState(() => _gameMode = set.first),
                ),
                const SizedBox(height: 20),

                // Player selection
                if (_gameMode == GameMode.singles) ...[
                  _buildPlayerDropdown('Player 1', _player1, users, (u) => setState(() => _player1 = u)),
                  const SizedBox(height: 12),
                  _buildPlayerDropdown('Player 2', _player2, users, (u) => setState(() => _player2 = u)),
                  if (_player1 != null && _player2 != null && _player1!.uid == _player2!.uid)
                    _buildWarning('Please select two different players'),
                ] else ...[
                  Text('Team 1', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryRed)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 1', _team1Player1, users, (u) => setState(() => _team1Player1 = u)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 2', _team1Player2, users, (u) => setState(() => _team1Player2 = u)),
                  const SizedBox(height: 16),
                  Text('Team 2', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.secondaryYellow)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 1', _team2Player1, users, (u) => setState(() => _team2Player1 = u)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 2', _team2Player2, users, (u) => setState(() => _team2Player2 = u)),
                  if (_hasDuplicateTeamPlayers)
                    _buildWarning('Each player can only appear once'),
                ],
                const SizedBox(height: 20),

                // Starting score
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
                const SizedBox(height: 20),

                // Format: best of / first to
                Text('Format', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<GameFormat>(
                  segments: const [
                    ButtonSegment(value: GameFormat.bestOf, label: Text('Best of')),
                    ButtonSegment(value: GameFormat.firstTo, label: Text('First to')),
                  ],
                  selected: {_gameFormat},
                  onSelectionChanged: (set) => setState(() => _gameFormat = set.first),
                ),
                const SizedBox(height: 16),

                // Legs
                _buildCountSelector(
                  'Legs',
                  _legsCount,
                  1,
                  10,
                  (v) => setState(() => _legsCount = v),
                ),
                const SizedBox(height: 12),

                // Sets (optional)
                Row(
                  children: [
                    Text('Sets', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Switch(
                      value: _setsCount > 0,
                      onChanged: (on) => setState(() => _setsCount = on ? 3 : 0),
                    ),
                  ],
                ),
                if (_setsCount > 0)
                  _buildCountSelector(
                    'Sets',
                    _setsCount,
                    1,
                    10,
                    (v) => setState(() => _setsCount = v),
                  ),
                const SizedBox(height: 20),

                // In/Out rules
                Text('Entry Rule', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<EntryRule>(
                  segments: const [
                    ButtonSegment(value: EntryRule.straightIn, label: Text('Straight In')),
                    ButtonSegment(value: EntryRule.doubleIn, label: Text('Double In')),
                  ],
                  selected: {_entryRule},
                  onSelectionChanged: (set) => setState(() => _entryRule = set.first),
                ),
                const SizedBox(height: 16),
                Text('Exit Rule', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<ExitRule>(
                  segments: const [
                    ButtonSegment(value: ExitRule.straightOut, label: Text('Straight Out')),
                    ButtonSegment(value: ExitRule.doubleOut, label: Text('Double Out')),
                  ],
                  selected: {_exitRule},
                  onSelectionChanged: (set) => setState(() => _exitRule = set.first),
                ),
                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: _canStartGame ? _startGame : null,
                  child: const Text('START GAME'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load players: $e')),
      ),
    );
  }

  bool get _canStartGame {
    if (_gameMode == GameMode.singles) {
      return _player1 != null && _player2 != null && _player1!.uid != _player2!.uid;
    } else {
      return _team1Player1 != null &&
          _team1Player2 != null &&
          _team2Player1 != null &&
          _team2Player2 != null &&
          !_hasDuplicateTeamPlayers;
    }
  }

  Widget _buildPlayerDropdown(
    String label,
    UserModel? selected,
    List<UserModel> users,
    ValueChanged<UserModel> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selected?.uid,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: users
          .map((u) => DropdownMenuItem(value: u.uid, child: Text(u.displayName)))
          .toList(),
      onChanged: (uid) {
        if (uid != null) {
          onChanged(users.firstWhere((u) => u.uid == uid));
        }
      },
    );
  }

  Widget _buildCountSelector(
    String label,
    int value,
    int min,
    int max,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      children: [
        IconButton(
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        IconButton(
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildWarning(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
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
          // Undo button
          IconButton(
            icon: Icon(
              Icons.undo,
              color: currentLeg.turns.isNotEmpty
                  ? AppColors.secondaryYellow
                  : AppColors.textMuted,
            ),
            tooltip: 'Undo last score',
            onPressed: currentLeg.turns.isNotEmpty
                ? () => ref.read(activeGameProvider.notifier).undoLastTurn()
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context, currentLeg),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard (includes per-player stats)
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
    String winnerLabel;
    if (game.gameMode == GameMode.teams && game.teams != null) {
      final teamIdx = game.teamIndexOf(winner.uid);
      final teamPlayers = game.players
          .where((p) => game.teams![teamIdx].contains(p.uid))
          .map((p) => p.displayName)
          .join(' & ');
      winnerLabel = teamPlayers;
    } else {
      winnerLabel = winner.displayName;
    }

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
                '$winnerLabel wins!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ...game.players.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      game.setsToWin > 0
                          ? '${p.displayName}: ${p.setsWon} sets'
                          : '${p.displayName}: ${p.legsWon} legs',
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
