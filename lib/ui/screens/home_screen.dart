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
              const SizedBox(height: 8),
              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                ),
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 4),
              currentUser.when(
                data: (user) => Text(
                  'Welcome, ${user?.displayName ?? 'Player'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 32),

              // Main actions
              _ActionButton(
                icon: Icons.gps_fixed,
                label: 'Local Game',
                subtitle: 'Play on this device',
                color: AppColors.primaryRed,
                onTap: () => context.push('/game'),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.wifi,
                label: 'Online Game',
                subtitle: 'Create or join a game',
                color: AppColors.primaryRedLight,
                onTap: () => context.push('/join'),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.track_changes,
                label: 'Doubles Training',
                subtitle: 'Around the Clock practice',
                color: AppColors.secondaryYellow,
                textColor: Colors.black,
                onTap: () => context.push('/doubles-training'),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.leaderboard,
                label: 'Leaderboards',
                subtitle: 'View rankings',
                color: AppColors.secondaryYellowDark,
                onTap: () => context.push('/leaderboard'),
              ),
              const Spacer(),

              // Profile button
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: TextButton.icon(
                  onPressed: () => context.push('/profile'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.person, size: 18, color: Colors.white),
                  label: const Text('My Profile & Statistics', style: TextStyle(fontSize: 15, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
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
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.textColor ?? Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: widget.color.withOpacity(_hovered ? 0.5 : 0.2),
              blurRadius: _hovered ? 16 : 6,
              offset: Offset(0, _hovered ? 8 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.color, widget.color.withOpacity(0.75)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: fgColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(widget.icon, color: fgColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.label,
                            style: TextStyle(
                              color: fgColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: fgColor.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: fgColor.withOpacity(0.6)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
