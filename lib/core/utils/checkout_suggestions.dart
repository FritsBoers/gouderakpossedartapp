import '../constants/checkout_table.dart';

/// Provides checkout route suggestions for a given remaining score.
class CheckoutSuggestions {
  CheckoutSuggestions._();

  /// Get formatted checkout suggestion for the current remaining score.
  /// Returns null if no checkout is possible.
  static String? getSuggestion(int remaining) {
    final checkouts = CheckoutTable.getCheckouts(remaining);
    if (checkouts.isEmpty) return null;
    // Return the first (optimal) checkout route as a formatted string.
    return checkouts.first.join(' → ');
  }

  /// Get all checkout options for a given remaining score.
  static List<String> getAllSuggestions(int remaining) {
    final checkouts = CheckoutTable.getCheckouts(remaining);
    return checkouts.map((route) => route.join(' → ')).toList();
  }

  /// Whether the remaining score is checkable.
  static bool canCheckout(int remaining) {
    return CheckoutTable.isCheckout(remaining);
  }

  /// Get the number of darts needed for checkout.
  static int? dartsNeeded(int remaining) {
    final checkouts = CheckoutTable.getCheckouts(remaining);
    if (checkouts.isEmpty) return null;
    return checkouts.first.length;
  }
}
