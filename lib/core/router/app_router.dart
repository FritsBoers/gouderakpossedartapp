import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart' show firebaseInitialized;
import '../../providers/auth_provider.dart';
import '../../ui/screens/home_screen.dart';
import '../../ui/screens/game_screen.dart';
import '../../ui/screens/leaderboard_screen.dart';
import '../../ui/screens/profile_screen.dart';
import '../../ui/screens/join_game_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/register_screen.dart';
import '../../ui/screens/verify_email_screen.dart';

/// Provides the app router configuration with auth-based redirects.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Skip auth guards if Firebase isn't configured (offline/local mode)
      if (!firebaseInitialized) return null;

      final authState = ref.watch(authStateProvider);
      final isLoggedIn = authState.valueOrNull != null;
      final isEmailVerified = authState.valueOrNull?.emailVerified ?? false;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';
      final isVerifyRoute = state.matchedLocation == '/verify-email';

      // Not logged in → redirect to login (unless already on auth route)
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in but not verified → redirect to verify (unless on verify/auth route)
      if (isLoggedIn && !isEmailVerified && !isVerifyRoute && !isAuthRoute) {
        return '/verify-email';
      }

      // Logged in and verified but on auth route → redirect to home
      if (isLoggedIn && isEmailVerified && (isAuthRoute || isVerifyRoute)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/join',
        builder: (context, state) => const JoinGameScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
    ],
  );
});
