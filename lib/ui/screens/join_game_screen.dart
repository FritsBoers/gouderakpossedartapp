import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../models/game_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';

/// Screen to create or join an online game via game code.
class JoinGameScreen extends ConsumerStatefulWidget {
  const JoinGameScreen({super.key});

  @override
  ConsumerState<JoinGameScreen> createState() => _JoinGameScreenState();
}

class _JoinGameScreenState extends ConsumerState<JoinGameScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  int _startingScore = 501;
  int _legsToWin = 3;
  ExitRule _exitRule = ExitRule.doubleOut;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createOnlineGame() async {
    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gameService = ref.read(gameServiceProvider);
      final game = await gameService.createGame(
        hostUid: user.uid,
        hostDisplayName: user.displayName ?? 'Player',
        startingScore: _startingScore,
        legsToWin: _legsToWin,
        exitRule: _exitRule,
        isOnline: true,
      );

      if (mounted) {
        context.push('/online-game/${game.id}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to create game');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinOnlineGame() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length != 6) {
      setState(() => _errorMessage = 'Game code must be 6 characters');
      return;
    }

    final authState = ref.read(authStateProvider);
    final user = authState.valueOrNull;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final gameService = ref.read(gameServiceProvider);
      final game = await gameService.joinGame(
        gameCode: code,
        playerUid: user.uid,
        playerDisplayName: user.displayName ?? 'Player',
      );

      if (game == null) {
        setState(() => _errorMessage = 'Game not found or already started');
      } else {
        if (mounted) {
          context.push('/online-game/${game.id}');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to join game');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Game')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create game section
            Text(
              'Create a Game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Game settings
            Text('Starting Score', style: Theme.of(context).textTheme.titleSmall),
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
            const SizedBox(height: 12),
            Text('Best of (legs)', style: Theme.of(context).textTheme.titleSmall),
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
            const SizedBox(height: 12),
            Text('Exit Rule', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ExitRule>(
              segments: const [
                ButtonSegment(value: ExitRule.doubleOut, label: Text('Double Out')),
                ButtonSegment(value: ExitRule.straightOut, label: Text('Straight Out')),
              ],
              selected: {_exitRule},
              onSelectionChanged: (set) => setState(() => _exitRule = set.first),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createOnlineGame,
              icon: const Icon(Icons.add),
              label: const Text('CREATE GAME'),
            ),

            const SizedBox(height: 32),
            const Divider(color: AppColors.surfaceLight),
            const SizedBox(height: 32),

            // Join game section
            Text(
              'Join a Game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                hintText: 'ENTER CODE',
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _joinOnlineGame,
              icon: const Icon(Icons.login),
              label: const Text('JOIN GAME'),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ],

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
