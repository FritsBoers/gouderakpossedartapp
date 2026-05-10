import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../models/leaderboard_entry.dart';

/// A badge earned by a player after a game.
class EarnedBadge {
  final String playerName;
  final LeaderboardCategory category;
  final int rank;

  const EarnedBadge({
    required this.playerName,
    required this.category,
    required this.rank,
  });
}

/// Shows a short animated celebration overlay for newly earned badges.
Future<void> showBadgeCelebration(
  BuildContext context,
  List<EarnedBadge> badges,
) async {
  if (badges.isEmpty) return;

  await showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Badge Celebration',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    transitionBuilder: (context, anim, secondAnim, child) {
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
          child: child,
        ),
      );
    },
    pageBuilder: (context, anim, secondAnim) {
      return _BadgeCelebrationContent(badges: badges);
    },
  );
}

class _BadgeCelebrationContent extends StatefulWidget {
  final List<EarnedBadge> badges;
  const _BadgeCelebrationContent({required this.badges});

  @override
  State<_BadgeCelebrationContent> createState() =>
      _BadgeCelebrationContentState();
}

class _BadgeCelebrationContentState extends State<_BadgeCelebrationContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _shimmer = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Auto-dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _rankColors = <int, Color>{
    1: AppColors.secondaryYellow,
    2: Color(0xFFC0C0C0),
    3: Color(0xFFCD7F32),
  };

  static const _rankLabels = <int, String>{
    1: '1st Place!',
    2: '2nd Place!',
    3: '3rd Place!',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.secondaryYellow.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondaryYellow.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shimmering stars
              AnimatedBuilder(
                animation: _shimmer,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final offset = i * 0.2;
                      final opacity =
                          (sin((_shimmer.value + offset) * pi * 2) * 0.4 + 0.6)
                              .clamp(0.3, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Opacity(
                          opacity: opacity,
                          child: Icon(
                            Icons.star,
                            color: AppColors.secondaryYellow,
                            size: i == 2 ? 26 : 18,
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 12),
              // Title
              const Text(
                'NEW BADGE!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondaryYellow,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 20),
              // Badge entries
              ...widget.badges.map((badge) {
                final color = _rankColors[badge.rank] ?? AppColors.textMuted;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: color, size: 28),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.playerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${_rankLabels[badge.rank]} — ${badge.category.displayName}',
                              style: TextStyle(
                                fontSize: 13,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              Text(
                'Tap anywhere to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
