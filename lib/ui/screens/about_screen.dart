import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class _ChangelogEntry {
  final String version;
  final String date;
  final List<String> changes;

  const _ChangelogEntry({
    required this.version,
    required this.date,
    required this.changes,
  });
}

const _changelog = [
  _ChangelogEntry(
    version: '1.0.0',
    date: '2026-05-15',
    changes: [
      'First release',
      'Lokale multiplayer mode ',
      'Online multiplayer mode ',
      'Checkout suggestions',
      'Player statistics & leaderboards',
      'Google & Email/Password authentication',
      'Doubles training mode',
    ],
  ),
];

/// About screen showing app version and changelog.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // App branding
          Center(
            child: Image.asset(
              'assets/images/logo.png',
              height: 80,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'GOUDERAK DARTS',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'App Designed and Built by FBIE',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'v${_changelog.first.version}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 32),

          // Changelog header
          Text(
            "What's New",
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.secondaryYellow,
                ),
          ),
          const SizedBox(height: 16),

          // Changelog entries
          ..._changelog.map((entry) => _ChangelogCard(entry: entry)),
        ],
      ),
    );
  }
}

class _ChangelogCard extends StatelessWidget {
  final _ChangelogEntry entry;

  const _ChangelogCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'v${entry.version}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  entry.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...entry.changes.map(
              (change) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Colors.white70)),
                    Expanded(
                      child: Text(
                        change,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
