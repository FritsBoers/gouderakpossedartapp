import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../services/tts_service.dart';

/// The 21 targets: D1–D20 then D-Bull.
const _targets = [
  'D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'D10',
  'D11', 'D12', 'D13', 'D14', 'D15', 'D16', 'D17', 'D18', 'D19', 'D20',
  'D-Bull',
];

/// Around the Clock Doubles training game.
/// Hit D1 → D2 → ... → D20 → D-Bull in order.
/// 3 darts per turn. Track total darts thrown to complete.
class DoublesTrainingScreen extends ConsumerStatefulWidget {
  const DoublesTrainingScreen({super.key});

  @override
  ConsumerState<DoublesTrainingScreen> createState() =>
      _DoublesTrainingScreenState();
}

class _DoublesTrainingScreenState extends ConsumerState<DoublesTrainingScreen> {
  int _currentTargetIndex = 0;
  int _totalDarts = 0;
  int _dartsThisTurn = 0;
  bool _gameStarted = false;
  bool _gameComplete = false;
  int? _personalBest;

  @override
  void initState() {
    super.initState();
    _loadPersonalBest();
  }

  Future<void> _loadPersonalBest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _personalBest = prefs.getInt('doublesTrainingBest');
    });
  }

  Future<void> _savePersonalBest(int darts) async {
    final prefs = await SharedPreferences.getInstance();
    if (_personalBest == null || darts < _personalBest!) {
      await prefs.setInt('doublesTrainingBest', darts);
      setState(() => _personalBest = darts);
    }
  }

  void _startGame() {
    setState(() {
      _currentTargetIndex = 0;
      _totalDarts = 0;
      _dartsThisTurn = 0;
      _gameStarted = true;
      _gameComplete = false;
    });
  }

  void _recordHit() {
    _totalDarts++;
    _dartsThisTurn++;

    ref.read(ttsServiceProvider).speakScore(
      _currentTargetIndex < 20
          ? (_currentTargetIndex + 1) * 2
          : 50, // D-Bull = 50
    );

    if (_currentTargetIndex + 1 >= _targets.length) {
      // Game complete
      _savePersonalBest(_totalDarts);
      setState(() {
        _gameComplete = true;
        _gameStarted = false;
      });
    } else {
      setState(() {
        _currentTargetIndex++;
        _dartsThisTurn = 0;
      });
    }
  }

  void _recordMiss() {
    _totalDarts++;
    _dartsThisTurn++;

    if (_dartsThisTurn >= 3) {
      // Turn over, stay on same target
      setState(() => _dartsThisTurn = 0);
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameComplete) {
      return _buildResultScreen();
    }
    if (!_gameStarted) {
      return _buildStartScreen();
    }
    return _buildGameplayScreen();
  }

  Widget _buildStartScreen() {
    return Scaffold(
      appBar: AppBar(title: const Text('Doubles Training')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.track_changes, size: 80, color: AppColors.secondaryYellow),
              const SizedBox(height: 24),
              Text(
                'Around the Clock\nDoubles',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Hit D1 \u2192 D2 \u2192 ... \u2192 D20 \u2192 D-Bull\n3 darts per turn. Fewest darts wins!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'This is practice only \u2014 no leaderboard impact.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              if (_personalBest != null) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryYellow.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.secondaryYellow.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.emoji_events, color: AppColors.secondaryYellow, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Personal Best: $_personalBest darts',
                        style: const TextStyle(
                          color: AppColors.secondaryYellow,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('START'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameplayScreen() {
    final target = _targets[_currentTargetIndex];
    final progress = _currentTargetIndex / _targets.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doubles Training'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Quit training',
          onPressed: () => _confirmQuit(),
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
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppColors.surfaceDark,
            color: AppColors.secondaryYellow,
            minHeight: 6,
          ),

          const SizedBox(height: 16),

          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatChip(label: 'Darts', value: '$_totalDarts'),
                _StatChip(
                  label: 'Target',
                  value: '${_currentTargetIndex + 1}/${_targets.length}',
                ),
                _StatChip(label: 'This turn', value: '${_dartsThisTurn}/3'),
              ],
            ),
          ),

          const Spacer(),

          // Current target
          Text(
            'Aim for',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryRed,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              target,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const Spacer(),

          // Hit / Miss buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _recordMiss,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'MISS',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 80,
                    child: ElevatedButton(
                      onPressed: _recordHit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'HIT',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultScreen() {
    final isNewBest = _personalBest == _totalDarts;

    return Scaffold(
      appBar: AppBar(title: const Text('Training Complete')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isNewBest ? Icons.star : Icons.check_circle,
                size: 80,
                color: isNewBest ? AppColors.secondaryYellow : Colors.green,
              ),
              const SizedBox(height: 24),
              if (isNewBest) ...[
                Text(
                  'New Personal Best!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.secondaryYellow,
                      ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Completed in',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_totalDarts darts',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 24),
              if (_personalBest != null && !isNewBest)
                Text(
                  'Personal best: $_personalBest darts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _startGame,
                child: const Text('PLAY AGAIN'),
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

  Future<void> _confirmQuit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quit Training?'),
        content: const Text('Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Quit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _gameStarted = false;
        _gameComplete = false;
      });
    }
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondaryYellow,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
