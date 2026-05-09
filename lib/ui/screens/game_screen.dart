import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/leaderboard_provider.dart';
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
  bool _statsUpdated = false;
  bool _throwForBull = false;
  bool _bullThrowPhase = false;
  List<GamePlayer> _pendingPlayers = [];
  List<List<String>>? _pendingTeams;
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

  void _startGame() => _startGameOrBullThrow();

  void _startGameOrBullThrow() {
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

    if (_throwForBull) {
      setState(() {
        _showSetup = false;
        _bullThrowPhase = true;
        _pendingPlayers = players;
        _pendingTeams = teams;
      });
    } else {
      _launchGame(players, teams);
    }
  }

  void _launchGame(List<GamePlayer> players, List<List<String>>? teams) {
    final legsToWin = _gameFormat == GameFormat.bestOf
        ? (_legsCount ~/ 2) + 1
        : _legsCount;

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

    setState(() {
      _showSetup = false;
      _statsUpdated = false;
      _bullThrowPhase = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSetup) {
      return _buildSetupScreen(context);
    }
    if (_bullThrowPhase) {
      return _buildBullThrowScreen(context);
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
          final sortedUsers = List<UserModel>.from(users)
            ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
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
                  _buildPlayerDropdown('Player 1', _player1, sortedUsers, (u) => setState(() => _player1 = u)),
                  const SizedBox(height: 12),
                  _buildPlayerDropdown('Player 2', _player2, sortedUsers, (u) => setState(() => _player2 = u)),
                  if (_player1 != null && _player2 != null && _player1!.uid == _player2!.uid)
                    _buildWarning('Please select two different players'),
                ] else ...[
                  Text('Team 1', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryRed)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 1', _team1Player1, sortedUsers, (u) => setState(() => _team1Player1 = u)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 2', _team1Player2, sortedUsers, (u) => setState(() => _team1Player2 = u)),
                  const SizedBox(height: 16),
                  Text('Team 2', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.secondaryYellow)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 1', _team2Player1, sortedUsers, (u) => setState(() => _team2Player1 = u)),
                  const SizedBox(height: 8),
                  _buildPlayerDropdown('Player 2', _team2Player2, sortedUsers, (u) => setState(() => _team2Player2 = u)),
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
                const SizedBox(height: 20),

                // Throw for bull
                Row(
                  children: [
                    Text('Throw for Bull', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    Switch(
                      value: _throwForBull,
                      onChanged: (on) => setState(() => _throwForBull = on),
                    ),
                  ],
                ),
                if (_throwForBull)
                  Text(
                    'Each player throws one dart at the bull to decide who goes first',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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
    return _PlayerDropdown(
      label: label,
      selected: selected,
      users: users,
      onChanged: onChanged,
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
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Stop game',
          onPressed: () => _confirmStopGame(context),
        ),
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
            onPressed: () => _showHistory(context, currentLeg, game.players),
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
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.secondaryYellow,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondaryYellow.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              '${currentPlayer.displayName}\'s turn',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
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
                color: AppColors.error.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                gameState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
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
    // Update stats once when game completes
    if (!_statsUpdated) {
      _statsUpdated = true;
      Future.microtask(() async {
        await ref.read(statsServiceProvider).updateStatsAfterGame(game: game);
        ref.invalidate(playerStatsProvider);
        await ref.read(leaderboardServiceProvider).clearCache();
        ref.invalidate(leaderboardProvider);
      });
    }

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

  Widget _buildBullThrowScreen(BuildContext context) {
    // In teams mode, show team choices; in singles, show player choices
    final isTeams = _gameMode == GameMode.teams && _pendingTeams != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Who Starts?'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() {
            _bullThrowPhase = false;
            _showSetup = true;
          }),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.gps_fixed, size: 48, color: AppColors.secondaryYellow),
            const SizedBox(height: 16),
            Text(
              'Throw for the bull!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.secondaryYellow,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              isTeams
                  ? 'Select the team that won the bull throw'
                  : 'Select the player that won the bull throw',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isTeams) ...[
              _buildTeamOption(0),
              const SizedBox(height: 12),
              _buildTeamOption(1),
            ] else
              ..._pendingPlayers.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _selectStarter(p.uid),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.secondaryYellow),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          p.displayName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryYellow,
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamOption(int teamIdx) {
    final teamPlayers = _pendingPlayers
        .where((p) => _pendingTeams![teamIdx].contains(p.uid))
        .map((p) => p.displayName)
        .join(' & ');

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: () => _selectStarter(_pendingTeams![teamIdx].first),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.secondaryYellow),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          teamPlayers,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.secondaryYellow,
          ),
        ),
      ),
    );
  }

  void _selectStarter(String winnerId) {
    List<GamePlayer> orderedPlayers;
    List<List<String>>? orderedTeams = _pendingTeams;

    if (_gameMode == GameMode.singles) {
      // Put winner first
      final winner = _pendingPlayers.firstWhere((p) => p.uid == winnerId);
      orderedPlayers = [
        winner,
        ..._pendingPlayers.where((p) => p.uid != winnerId),
      ];
    } else {
      int winnerTeamIdx = 0;
      if (_pendingTeams != null) {
        for (int i = 0; i < _pendingTeams!.length; i++) {
          if (_pendingTeams![i].contains(winnerId)) {
            winnerTeamIdx = i;
            break;
          }
        }
      }
      if (winnerTeamIdx == 1) {
        orderedPlayers = [
          _pendingPlayers[1],
          _pendingPlayers[0],
          _pendingPlayers[3],
          _pendingPlayers[2],
        ];
        if (_pendingTeams != null) {
          orderedTeams = [_pendingTeams![1], _pendingTeams![0]];
        }
      } else {
        orderedPlayers = _pendingPlayers;
      }
    }

    _launchGame(orderedPlayers, orderedTeams);
  }

  void _confirmStopGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop Game'),
        content: const Text('Are you sure you want to stop the current game? All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(activeGameProvider.notifier).resetGame();
              Navigator.of(context).pop();
            },
            child: const Text('STOP GAME'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, Leg currentLeg, List<GamePlayer> players) {
    showModalBottomSheet(
      context: context,
      builder: (context) => TurnHistory(turns: currentLeg.turns, players: players),
    );
  }
}

class _PlayerDropdown extends StatefulWidget {
  final String label;
  final UserModel? selected;
  final List<UserModel> users;
  final ValueChanged<UserModel> onChanged;

  const _PlayerDropdown({
    required this.label,
    required this.selected,
    required this.users,
    required this.onChanged,
  });

  @override
  State<_PlayerDropdown> createState() => _PlayerDropdownState();
}

class _PlayerDropdownState extends State<_PlayerDropdown> {
  bool _isOpen = false;
  bool _enteringGuest = false;
  final _guestController = TextEditingController();
  final _guestFocus = FocusNode();

  @override
  void dispose() {
    _guestController.dispose();
    _guestFocus.dispose();
    super.dispose();
  }

  void _submitGuest() {
    final name = _guestController.text.trim();
    if (name.isEmpty) return;
    widget.onChanged(UserModel.guest(name));
    setState(() {
      _isOpen = false;
      _enteringGuest = false;
      _guestController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show guest label with icon if selected is a guest
    final displayText = widget.selected != null
        ? widget.selected!.isGuest
            ? '${widget.selected!.displayName} (Guest)'
            : widget.selected!.displayName
        : widget.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => setState(() {
            _isOpen = !_isOpen;
            if (!_isOpen) _enteringGuest = false;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border.all(
                color: _isOpen ? AppColors.secondaryYellow : AppColors.textMuted,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: widget.selected != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 16,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _isOpen ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
        ClipRect(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _isOpen
                ? Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.textMuted.withValues(alpha: 0.3),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        // Guest option
                        if (!_enteringGuest)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _enteringGuest = true);
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  _guestFocus.requestFocus();
                                });
                              },
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(Icons.person_add_alt_1,
                                        size: 18, color: AppColors.textMuted),
                                    SizedBox(width: 8),
                                    Text(
                                      'Play as Guest',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _guestController,
                                    focusNode: _guestFocus,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary),
                                    decoration: InputDecoration(
                                      hintText: 'Enter guest name',
                                      hintStyle: const TextStyle(
                                          color: AppColors.textMuted),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                    ),
                                    onSubmitted: (_) => _submitGuest(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _submitGuest,
                                  icon: const Icon(Icons.check,
                                      color: AppColors.success),
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                                IconButton(
                                  onPressed: () => setState(() {
                                    _enteringGuest = false;
                                    _guestController.clear();
                                  }),
                                  icon: const Icon(Icons.close,
                                      color: AppColors.textMuted),
                                  constraints: const BoxConstraints(
                                      minWidth: 36, minHeight: 36),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        // Divider between guest option and user list
                        Divider(
                          height: 1,
                          color: AppColors.textMuted.withValues(alpha: 0.2),
                        ),
                        // Registered users (scrollable)
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: widget.users.map((u) {
                                final isSelected = widget.selected?.uid == u.uid;
                                return Material(
                                  color: isSelected
                                      ? AppColors.secondaryYellow
                                          .withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      widget.onChanged(u);
                                      setState(() {
                                        _isOpen = false;
                                        _enteringGuest = false;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: Text(
                                        u.displayName,
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppColors.secondaryYellow
                                              : AppColors.textPrimary,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ),
      ],
    );
  }
}
