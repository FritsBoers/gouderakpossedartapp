import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/checkout_suggestions.dart';

/// Displays checkout route suggestion when player is in checkout range.
class CheckoutSuggestionWidget extends StatelessWidget {
  final int remaining;

  const CheckoutSuggestionWidget({
    super.key,
    required this.remaining,
  });

  @override
  Widget build(BuildContext context) {
    final suggestion = CheckoutSuggestions.getSuggestion(remaining);
    if (suggestion == null) return const SizedBox.shrink();

    final dartsNeeded = CheckoutSuggestions.dartsNeeded(remaining);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: AppColors.secondaryYellow.withOpacity(0.15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lightbulb_outline, size: 18, color: AppColors.secondaryYellow),
          const SizedBox(width: 8),
          Text(
            suggestion,
            style: const TextStyle(
              color: AppColors.secondaryYellow,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          if (dartsNeeded != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.secondaryYellow.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${dartsNeeded}d',
                style: const TextStyle(
                  color: AppColors.secondaryYellow,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
