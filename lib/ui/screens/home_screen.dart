import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Home screen with navigation to game modes, leaderboards, and profile.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              // Header
              Text(
                'GOUDERAK POSSE',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.secondaryYellow,
                      letterSpacing: 2,
                    ),
              ),
              Text(
                'DARTS',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              currentUser.when(
                data: (user) => Text(
                  'Welcome, ${user?.displayName ?? 'Player'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 48),

              // Main actions
              _ActionButton(
                icon: Icons.sports_esports,
                label: 'Local Game',
                subtitle: 'Play on this device',
                color: AppColors.primaryRed,
                onTap: () => context.push('/game'),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.wifi,
                label: 'Online Game',
                subtitle: 'Create or join a game',
                color: AppColors.primaryRedLight,
                onTap: () => context.push('/join'),
              ),
              const SizedBox(height: 16),
              _ActionButton(
                icon: Icons.leaderboard,
                label: 'Leaderboards',
                subtitle: 'View rankings',
                color: AppColors.secondaryYellow,
                textColor: Colors.black,
                onTap: () => context.push('/leaderboard'),
              ),
              const Spacer(),

              // Profile button
              OutlinedButton.icon(
                onPressed: () => context.push('/profile'),
                icon: const Icon(Icons.person),
                label: const Text('Profile & Stats'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final Color? textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = textColor ?? Colors.white;

    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: fgColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: fgColor.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: fgColor),
            ],
          ),
        ),
      ),
    );
  }
}
