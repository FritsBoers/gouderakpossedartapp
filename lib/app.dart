import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';

/// Root widget for the Gouderak Posse Darts application.
class GouderakDartsApp extends ConsumerWidget {
  const GouderakDartsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Gouderak Posse Darts',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final width = MediaQuery.of(context).size.width;
        // Full width on mobile (<600), 80% on tablet, 60% on desktop
        final double widthFactor = width < 600
            ? 1.0
            : width < 1200
                ? 0.8
                : 0.6;
        return Center(
          child: FractionallySizedBox(
            widthFactor: widthFactor,
            child: child,
          ),
        );
      },
    );
  }
}
