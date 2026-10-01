import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/ideas/presentation/idea_detail_screen.dart';
import '../features/postmortem/presentation/postmortem_screen.dart';
import '../features/projects/presentation/project_memory_screen.dart';
import '../features/projects/presentation/project_workspace_screen.dart';
import '../features/reforge/presentation/reforge_wizard_screen.dart';
import 'shell_screen.dart';

/// Helper to convert a [Stream] to a [Listenable] for GoRouter refresh.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider managing the application [GoRouter] configuration and route guards.
final routerProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final refreshListenable = GoRouterRefreshStream(authRepository.authStateChanges);

  ref.onDispose(refreshListenable.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refreshListenable,
    redirect: (BuildContext context, GoRouterState state) {
      final currentSession = authRepository.getCurrentSession();
      final currentUser = authRepository.currentUser;
      final isAuthenticated = currentSession != null || currentUser != null;

      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/signup';

      // If user is unauthenticated and attempting to access protected routes,
      // redirect them to the /login screen.
      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      // If user is authenticated and navigating to auth screens (/login, /signup),
      // redirect them straight to /home.
      if (isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(isSignUp: false),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const LoginScreen(isSignUp: true),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ReforgeShellScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ReforgeDesktopShell(child: ProfileScreen()),
      ),
      GoRoute(
        path: '/projects/:id',
        builder: (context, state) {
          final projectId = state.pathParameters['id'] ?? '';
          return ReforgeDesktopShell(child: ProjectWorkspaceScreen(projectId: projectId));
        },
      ),
      GoRoute(
        path: '/projects/:id/memory',
        builder: (context, state) {
          final projectId = state.pathParameters['id'] ?? '';
          return ReforgeDesktopShell(child: ProjectMemoryScreen(projectId: projectId));
        },
      ),
      GoRoute(
        path: '/postmortem/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return ReforgeDesktopShell(child: PostmortemScreen(projectId: projectId));
        },
      ),
      GoRoute(
        path: '/ideas/:id',
        builder: (context, state) {
          final ideaId = state.pathParameters['id'] ?? '';
          return ReforgeDesktopShell(child: IdeaDetailScreen(ideaId: ideaId));
        },
      ),
      GoRoute(
        path: '/reforge/:sourceProjectId',
        builder: (context, state) {
          final sourceProjectId = state.pathParameters['sourceProjectId'] ?? '';
          return ReforgeDesktopShell(child: ReforgeWizardScreen(sourceProjectId: sourceProjectId));
        },
      ),
    ],
  );
});
