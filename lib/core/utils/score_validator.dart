import '../constants/game_constants.dart';
import '../../models/game_model.dart';

/// Result of score validation.
class ScoreValidation {
  final bool isValid;
  final String? errorMessage;
  final bool isBust;
  final bool isCheckout;

  const ScoreValidation({
    required this.isValid,
    this.errorMessage,
    this.isBust = false,
    this.isCheckout = false,
  });

  static const ScoreValidation valid = ScoreValidation(isValid: true);
}

/// Validates dart scores and turn inputs.
class ScoreValidator {
  ScoreValidator._();

  /// Validate a turn score against the player's remaining score.
  /// Supports configurable entry/exit rules.
  static ScoreValidation validateTurn({
    required int turnScore,
    required int remainingScore,
    required bool lastDartDouble,
    bool firstDartDouble = false,
    EntryRule entryRule = EntryRule.straightIn,
    ExitRule exitRule = ExitRule.doubleOut,
    bool hasOpenedScoring = true,
  }) {
    // Check turn score is in valid range
    if (turnScore < 0 || turnScore > GameConstants.maxTurnScore) {
      return const ScoreValidation(
        isValid: false,
        errorMessage: 'Score must be between 0 and 180',
      );
    }

    // Check if score is actually achievable with 3 darts
    if (!GameConstants.isPossibleTurnScore(turnScore)) {
      return ScoreValidation(
        isValid: false,
        errorMessage: '$turnScore is not achievable with 3 darts',
      );
    }

    // Double-in rule: if player hasn't opened scoring yet, first dart must be double
    if (entryRule == EntryRule.doubleIn && !hasOpenedScoring) {
      if (!firstDartDouble) {
        // Entire turn is wasted — score doesn't count
        return const ScoreValidation(
          isValid: true,
          isBust: true,
        );
      }
    }

    final newRemaining = remainingScore - turnScore;

    // Bust: score goes below 0
    if (newRemaining < 0) {
      return const ScoreValidation(
        isValid: true,
        isBust: true,
      );
    }

    if (exitRule == ExitRule.doubleOut) {
      // Bust: score goes to exactly 1 (can't finish with double)
      if (newRemaining == 1) {
        return const ScoreValidation(
          isValid: true,
          isBust: true,
        );
      }

      // Checkout: score reaches 0 — must finish on a double
      if (newRemaining == 0) {
        if (!lastDartDouble) {
          return const ScoreValidation(
            isValid: true,
            isBust: true,
          );
        }
        return const ScoreValidation(
          isValid: true,
          isCheckout: true,
        );
      }
    } else {
      // Straight out: just reach 0
      if (newRemaining == 0) {
        return const ScoreValidation(
          isValid: true,
          isCheckout: true,
        );
      }
    }

    return ScoreValidation.valid;
  }

  /// Validate a single dart score value.
  static bool isValidSingleDart(int score) {
    return GameConstants.validSingleDartScores.contains(score);
  }

  /// Check if a score can be finished (is within checkout range).
  static bool isInCheckoutRange(int remaining) {
    return remaining >= GameConstants.minCheckout &&
        remaining <= GameConstants.maxCheckout;
  }

  /// Validate that a finishing score was on a double.
  /// Used when detailed dart input is available.
  static bool isDoubleFinish(int segment, bool isDouble) {
    if (!isDouble) return false;
    if (segment == 25) return true; // bullseye
    return segment >= 1 && segment <= 20;
  }
}
