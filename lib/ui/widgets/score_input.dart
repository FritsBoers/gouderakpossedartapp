import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/game_constants.dart';
import '../../core/utils/checkout_suggestions.dart';

/// Numpad-style score input widget for fast 3-dart total entry.
/// Large buttons, mobile-first layout.
class ScoreInput extends StatefulWidget {
  final void Function(int score, bool lastDartDouble) onScoreSubmitted;
  final int remainingScore;

  const ScoreInput({
    super.key,
    required this.onScoreSubmitted,
    required this.remainingScore,
  });

  @override
  State<ScoreInput> createState() => _ScoreInputState();
}

class _ScoreInputState extends State<ScoreInput> {
  String _input = '';
  bool _lastDartDouble = false;

  void _addDigit(String digit) {
    if (_input.length >= 3) return; // Max 180 = 3 digits
    setState(() => _input += digit);
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _clear() {
    setState(() {
      _input = '';
      _lastDartDouble = false;
    });
  }

  void _submit() {
    final score = int.tryParse(_input) ?? 0;

    if (!GameConstants.isPossibleTurnScore(score)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$score is not a valid 3-dart score',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    widget.onScoreSubmitted(score, _lastDartDouble);
    setState(() {
      _input = '';
      _lastDartDouble = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final score = int.tryParse(_input) ?? 0;
    final isCheckoutAttempt = widget.remainingScore <= GameConstants.maxCheckout;

    return Column(
      children: [
        // Score display with backspace button
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48), // Balance the row
            Expanded(
              child: Text(
                _input.isEmpty ? '0' : _input,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 56,
                    ),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                onPressed: _input.isNotEmpty ? _backspace : null,
                icon: const Icon(Icons.backspace_outlined, size: 28),
                color: AppColors.error,
                disabledColor: AppColors.textMuted.withOpacity(0.3),
              ),
            ),
          ],
        ),

        // Double-out toggle (shown when in checkout range)
        if (isCheckoutAttempt && _input.isNotEmpty && score == widget.remainingScore)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Finished on double?'),
                const SizedBox(width: 8),
                Switch(
                  value: _lastDartDouble,
                  onChanged: (v) => setState(() => _lastDartDouble = v),
                  activeThumbColor: AppColors.secondaryYellow,
                ),
              ],
            ),
          ),

        // Numpad
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildRow(['1', '2', '3']),
                _buildRow(['4', '5', '6']),
                _buildRow(['7', '8', '9']),
                _buildBottomRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> digits) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: digits
            .map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumpadButton(
                      label: d,
                      onTap: () => _addDigit(d),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Clear button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _NumpadButton(
                label: 'C',
                color: AppColors.surfaceLight,
                onTap: _clear,
              ),
            ),
          ),
          // 0 button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _NumpadButton(
                label: '0',
                onTap: () => _addDigit('0'),
              ),
            ),
          ),
          // Submit button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: _NumpadButton(
                label: 'Submit',
                color: AppColors.primaryRed,
                onTap: _submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _NumpadButton({
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color ?? AppColors.surfaceDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
