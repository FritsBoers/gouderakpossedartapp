import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/checkout_suggestions.dart';
import '../../core/utils/score_validator.dart';
import '../../models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/leaderboard_provider.dart';
import '../../models/leaderboard_entry.dart';
import '../../services/tts_service.dart';
import '../widgets/badge_celebration.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/score_input.dart';
import '../widgets/scoreboard.dart';
import '../widgets/checkout_suggestion.dart';
import '../widgets/turn_history.dart';

/// Online game screen that streams game state from Firestore.
class OnlineGameScreen extends ConsumerStatefulWidget {
  final String gameId;

  const OnlineGameScreen({super.key, required this.gameId});

  @override
  ConsumerState<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends ConsumerState<OnlineGameScreen> {
  bool _statsUpdated = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final gameStream = ref.watch(gameStreamProvider(widget.gameId));
    final authState = ref.watch(authStateProvider);
    final myUid = authState.valueOrNull?.uid ?? '';

    return gameStream.when(
      data: (game) {
        if (game == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Online Game')),
            body: const Center(child: Text('Game not found')),
          );
        }

        if (game.status == GameStatus.waiting) {
          return _buildWaitingScreen(context, game, myUid);
        }

        if (game.status == GameStatus.completed) {
          return _buildGameOverScreen(context, game);
        }

        return _buildGameScreen(context, game, myUid);
      },
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Online Game')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Online Game')),
        body: Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildWaitingScreen(BuildContext context, GameModel game, String myUid) {
    final isHost = game.playerIds.first == myUid;
    final hasOpponent = game.players.length >= 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Online Game')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isHost) ...[
              // Host view
              Text(
                'Game Code',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  game.gameCode,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 6,
                    color: AppColors.secondaryYellow,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Settings: ${game.startingScore} | Best of ${game.legsToWin} legs | ${game.exitRule.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 32),
              if (!hasOpponent) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Waiting for opponent to join...',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.secondaryYellow, width: 2),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.secondaryYellow, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        '${game.players.last.displayName} joined!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.secondaryYellow,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _startGame(game),
                  child: const Text('START GAME'),
                ),
              ],
            ] else ...[
              // Joiner view — waiting for host to start
              const Icon(Icons.hourglass_top, size: 48, color: AppColors.secondaryYellow),
              const SizedBox(height: 16),
              Text(
                'Joined successfully!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.secondaryYellow,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for ${game.players.first.displayName} to start the game...',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white70,
                    ),
              ),
              const SizedBox(height: 24),
              Text(
                '${game.startingScore} | Best of ${game.legsToWin} legs | ${game.exitRule.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _startGame(GameModel game) async {
    try {
      final gameService = ref.read(gameServiceProvider);
      await gameService.startGame(game.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start game: $e')),
        );
      }
    }
  }

  Widget _buildGameScreen(BuildContext context, GameModel game, String myUid) {
    final currentLegIndex = game.legs.length - 1;
    final currentLeg = game.legs[currentLegIndex];
    final currentPlayerId = game.currentPlayerId;
    final currentPlayer = game.players.firstWhere((p) => p.uid == currentPlayerId);
    final remaining = currentLeg.playerScores[currentPlayerId] ?? 0;
    final isMyTurn = currentPlayerId == myUid;

    return Scaffold(
      appBar: AppBar(
        title: Text('Leg ${currentLegIndex + 1}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Leave game',
          onPressed: () => _confirmLeaveGame(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(ttsEnabledProvider) ? Icons.volume_up : Icons.volume_off,
              color: ref.watch(ttsEnabledProvider)
                  ? AppColors.secondaryYellow
                  : AppColors.textMuted,
            ),
            tooltip: 'Toggle score audio',
            onPressed: () => ref.read(ttsServiceProvider).toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistory(context, currentLeg, game.players),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scoreboard
          Scoreboard(
            game: game,
            currentLegIndex: currentLegIndex,
          ),

          // Current player indicator
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isMyTurn ? AppColors.secondaryYellow : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(14),
              boxShadow: isMyTurn
                  ? [
                      BoxShadow(
                        color: AppColors.secondaryYellow.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              isMyTurn
                  ? 'Your turn!'
                  : "Waiting for ${currentPlayer.displayName}...",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isMyTurn ? Colors.black : Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Checkout suggestion
          if (isMyTurn && CheckoutSuggestions.canCheckout(remaining))
            CheckoutSuggestionWidget(remaining: remaining),

          // Error message
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.85),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          // Score input (only enabled when it's my turn)
          Expanded(
            child: isMyTurn
                ? ScoreInput(
                    onScoreSubmitted: (score, isDouble) =>
                        _submitOnlineTurn(game, currentLegIndex, score, isDouble),
                    remainingScore: remaining,
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.hourglass_top,
                            size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          '${currentPlayer.displayName} is throwing...',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textMuted,
                              ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitOnlineTurn(
    GameModel game,
    int legIndex,
    int turnScore,
    bool lastDartDouble,
  ) async {
    final playerId = game.currentPlayerId;
    final currentLeg = game.legs[legIndex];
    final remaining = currentLeg.playerScores[playerId] ?? 0;

    // Validate
    final hasOpenedScoring = game.entryRule == EntryRule.straightIn ||
        remaining < game.startingScore;

    final validation = ScoreValidator.validateTurn(
      turnScore: turnScore,
      remainingScore: remaining,
      lastDartDouble: lastDartDouble,
      entryRule: game.entryRule,
      exitRule: game.exitRule,
      hasOpenedScoring: hasOpenedScoring,
    );

    if (!validation.isValid) {
      setState(() => _errorMessage = validation.errorMessage);
      return;
    }

    setState(() => _errorMessage = null);

    ref.read(ttsServiceProvider).speakScore(turnScore);

    final turn = Turn(
      playerId: playerId,
      darts: [],
      totalScore: turnScore,
      isBust: validation.isBust,
      timestamp: DateTime.now(),
    );

    final newRemainingScore = validation.isBust ? remaining : remaining - turnScore;
    final isLegWon = validation.isCheckout;

    // Determine next player
    final currentIndex = game.playerIds.indexOf(playerId);
    String nextPlayerId;
    if (isLegWon) {
      // Next leg: alternate starting player
      final legStarterId = currentLeg.turns.isNotEmpty
          ? currentLeg.turns.first.playerId
          : game.playerIds.first;
      final starterIndex = game.playerIds.indexOf(legStarterId);
      nextPlayerId = game.playerIds[(starterIndex + 1) % game.playerIds.length];
    } else {
      nextPlayerId = game.playerIds[(currentIndex + 1) % game.playerIds.length];
    }

    try {
      await ref.read(gameServiceProvider).submitTurn(
            gameId: game.id,
            turn: turn,
            legIndex: legIndex,
            newRemainingScore: newRemainingScore,
            isBust: validation.isBust,
            isLegWon: isLegWon,
            nextPlayerId: nextPlayerId,
          );
    } catch (e) {
      setState(() => _errorMessage = 'Failed to submit score');
    }
  }

  Widget _buildGameOverScreen(BuildContext context, GameModel game) {
    if (!_statsUpdated) {
      _statsUpdated = true;
      Future.microtask(() async {
        try {
          await ref.read(statsServiceProvider).updateStatsAfterGame(game: game);
        } catch (e) {
          debugPrint('Stats update failed: $e');
        }
        ref.invalidate(playerStatsProvider);
        await ref.read(leaderboardServiceProvider).clearCache();
        for (final cat in LeaderboardCategory.values) {
          ref.invalidate(leaderboardProvider(cat));
        }

        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;
        final playerUids = game.players
            .where((p) => !p.uid.startsWith('guest_'))
            .map((p) => p.uid)
            .toSet();
        final playerNames = {
          for (final p in game.players) p.uid: p.displayName,
        };
        final earnedBadges = <EarnedBadge>[];
        final service = ref.read(leaderboardServiceProvider);
        for (final cat in LeaderboardCategory.values) {
          try {
            final entries = await service.getLeaderboard(cat, forceRefresh: true);
            for (final entry in entries) {
              if (entry.rank <= 3 && playerUids.contains(entry.uid)) {
                earnedBadges.add(EarnedBadge(
                  playerName: playerNames[entry.uid] ?? entry.displayName,
                  category: cat,
                  rank: entry.rank,
                ));
              }
            }
          } catch (_) {}
        }
        if (earnedBadges.isNotEmpty && mounted) {
          showBadgeCelebration(context, earnedBadges);
        }
      });
    }

    final winner = game.players.firstWhere((p) => p.uid == game.winnerId);

    return ConfettiOverlay(
      child: Scaffold(
        appBar: AppBar(title: const Text('Game Over')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: AppColors.secondaryYellow),
                const SizedBox(height: 16),
                Text(
                  '${winner.displayName} wins!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.secondaryYellow,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  _buildScoreSummary(game),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.go('/'),
                  child: const Text('BACK TO HOME'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildScoreSummary(GameModel game) {
    final scores = game.players.map((p) => '${p.displayName}: ${p.legsWon} legs').join('\n');
    return scores;
  }

  void _confirmLeaveGame(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Game?'),
        content: const Text('You will leave this online game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('Leave', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, Leg leg, List<GamePlayer> players) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => TurnHistory(turns: leg.turns, players: players),
    );
  }
}
