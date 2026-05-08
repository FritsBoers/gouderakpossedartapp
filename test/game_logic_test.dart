import 'package:flutter_test/flutter_test.dart';
import 'package:gouderakpossedartapp/core/utils/score_validator.dart';
import 'package:gouderakpossedartapp/core/utils/checkout_suggestions.dart';
import 'package:gouderakpossedartapp/core/constants/game_constants.dart';

void main() {
  group('ScoreValidator', () {
    test('valid turn score accepted', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 60,
        remainingScore: 501,
        lastDartDouble: false,
      );
      expect(result.isValid, true);
      expect(result.isBust, false);
    });

    test('score over 180 rejected', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 181,
        remainingScore: 501,
        lastDartDouble: false,
      );
      expect(result.isValid, false);
    });

    test('impossible score rejected', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 179,
        remainingScore: 501,
        lastDartDouble: false,
      );
      expect(result.isValid, false);
    });

    test('bust when remaining goes below zero', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 100,
        remainingScore: 50,
        lastDartDouble: false,
      );
      expect(result.isValid, true);
      expect(result.isBust, true);
    });

    test('bust when remaining becomes 1', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 39,
        remainingScore: 40,
        lastDartDouble: false,
      );
      expect(result.isValid, true);
      expect(result.isBust, true);
    });

    test('checkout requires double', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 40,
        remainingScore: 40,
        lastDartDouble: false,
      );
      expect(result.isValid, true);
      expect(result.isBust, true);
      expect(result.isCheckout, false);
    });

    test('checkout with double succeeds', () {
      final result = ScoreValidator.validateTurn(
        turnScore: 40,
        remainingScore: 40,
        lastDartDouble: true,
      );
      expect(result.isValid, true);
      expect(result.isCheckout, true);
      expect(result.isBust, false);
    });
  });

  group('CheckoutSuggestions', () {
    test('170 checkout is T20 T20 BULL', () {
      final suggestion = CheckoutSuggestions.getSuggestion(170);
      expect(suggestion, 'T20 → T20 → BULL');
    });

    test('100 checkout is T20 D20', () {
      final suggestion = CheckoutSuggestions.getSuggestion(100);
      expect(suggestion, 'T20 → D20');
    });

    test('40 checkout is D20', () {
      final suggestion = CheckoutSuggestions.getSuggestion(40);
      expect(suggestion, 'D20');
    });

    test('32 checkout is D16', () {
      final suggestion = CheckoutSuggestions.getSuggestion(32);
      expect(suggestion, 'D16');
    });

    test('no checkout for score > 170', () {
      final suggestion = CheckoutSuggestions.getSuggestion(171);
      expect(suggestion, null);
    });

    test('no checkout for score < 2', () {
      final suggestion = CheckoutSuggestions.getSuggestion(1);
      expect(suggestion, null);
    });

    test('canCheckout returns true for valid checkout', () {
      expect(CheckoutSuggestions.canCheckout(50), true);
    });

    test('canCheckout returns false for impossible score', () {
      expect(CheckoutSuggestions.canCheckout(200), false);
    });
  });

  group('GameConstants', () {
    test('180 is valid turn score', () {
      expect(GameConstants.isPossibleTurnScore(180), true);
    });

    test('0 is valid turn score (miss all)', () {
      expect(GameConstants.isPossibleTurnScore(0), true);
    });

    test('179 is impossible', () {
      expect(GameConstants.isPossibleTurnScore(179), false);
    });

    test('negative score is invalid', () {
      expect(GameConstants.isPossibleTurnScore(-1), false);
    });
  });
}
