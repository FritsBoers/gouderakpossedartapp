import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
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
        isOnline: true,
      );

      if (mounted) {
        _showGameCode(game.gameCode);
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
          ref.read(activeGameProvider.notifier).loadGame(game);
          context.push('/game');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to join game');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showGameCode(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Game Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your opponent:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.secondaryYellow,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Waiting for opponent to join...',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Online Game')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create game section
            Text(
              'Create a Game',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _createOnlineGame,
              icon: const Icon(Icons.add),
              label: const Text('CREATE GAME'),
            ),

            const SizedBox(height: 40),
            const Divider(color: AppColors.surfaceLight),
            const SizedBox(height: 40),

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
