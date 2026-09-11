import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghanaserve/models/service_model.dart';
import 'package:ghanaserve/providers/auth_provider.dart';
import 'package:ghanaserve/data/services_data.dart';
import 'package:ghanaserve/screens/shell_screen.dart';
import 'package:ghanaserve/screens/home_screen.dart';
import 'package:ghanaserve/screens/services_screen.dart';
import 'package:ghanaserve/screens/service_detail_screen.dart';
import 'package:ghanaserve/screens/apply_screen.dart';
import 'package:ghanaserve/screens/track_screen.dart';
import 'package:ghanaserve/screens/profile_screen.dart';
import 'package:ghanaserve/screens/notifications_screen.dart';
import 'package:ghanaserve/screens/history_screen.dart';
import 'package:ghanaserve/screens/settings_screen.dart';
import 'package:ghanaserve/screens/funds_screen.dart';
import 'package:ghanaserve/screens/funds_flow_screen.dart';
import 'package:ghanaserve/screens/about_screen.dart';
import 'package:ghanaserve/screens/support_screen.dart';
import 'package:ghanaserve/screens/splash_screen.dart';
import 'package:ghanaserve/screens/auth/login_screen.dart';
import 'package:ghanaserve/screens/auth/signup_screen.dart';
import 'package:ghanaserve/screens/auth/verify_account_screen.dart';
import 'package:ghanaserve/screens/admin_login_screen.dart';
import 'package:ghanaserve/screens/admin_dashboard_screen.dart';
import 'package:ghanaserve/theme/app_theme.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Rebuild the router whenever auth state changes
  final authListenable = _AuthChangeNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authState = ref.read(authProvider).valueOrNull;
      final isLoading = authState == null || authState.isLoading;

      // While auth state is initialising, stay on splash
      if (isLoading) {
        return state.matchedLocation == '/splash' ? null : '/splash';
      }

      final isAuthenticated = authState.isAuthenticated;
      final isStaff = authState.user?.isStaff == true;
      if (state.matchedLocation == '/splash') {
        return isAuthenticated ? (isStaff ? '/admin' : '/home') : '/login';
      }

      final onAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/admin-login';

      // Unauthenticated user trying to access protected routes → login
      if (!isAuthenticated && !onAuthRoute) return '/login';

      // Authenticated user hitting auth routes → home
      if (isAuthenticated && onAuthRoute) return isStaff ? '/admin' : '/home';
      if (state.matchedLocation == '/admin' && !isStaff) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/admin-login',
        builder: (context, state) => Theme(
          data: AppTheme.lightTheme,
          child: const AdminLoginScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => Theme(
          data: AppTheme.lightTheme,
          child: const AdminDashboardScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HomeScreen()),
          ),
          GoRoute(
            path: '/services',
            pageBuilder: (context, state) {
              final category = state.extra is ServiceCategory
                  ? state.extra as ServiceCategory
                  : null;
              return NoTransitionPage(
                child: ServicesScreen(category: category),
              );
            },
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  final extra = state.extra;
                  final service = extra is GovernmentService
                      ? extra
                      : (extra as Map<String, dynamic>)['service']
                          as GovernmentService;
                  return ServiceDetailScreen(service: service);
                },
                routes: [
                  GoRoute(
                    path: 'apply',
                    builder: (context, state) {
                      final extra = state.extra as Map<String, dynamic>;
                      return ApplyScreen(
                        service: extra['service'] as GovernmentService,
                        draft: extra['draft'] as CitizenApplication?,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/track',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TrackScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProfileScreen()),
          ),
          GoRoute(
            path: '/verify-account',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: VerifyAccountScreen()),
          ),
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: NotificationsScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HistoryScreen()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsScreen()),
          ),
          GoRoute(
            path: '/funds',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: FundsScreen()),
          ),
          GoRoute(
            path: '/funds/add-method',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AddPaymentMethodScreen()),
          ),
          GoRoute(
            path: '/funds/add',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AddFundsScreen()),
          ),
          GoRoute(
            path: '/funds/withdraw',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: WithdrawFundsScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AboutScreen()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PrivacyPolicyScreen()),
          ),
          GoRoute(
            path: '/support',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SupportScreen()),
          ),
        ],
      ),
    ],
  );
});

/// Tells GoRouter to re-evaluate redirects when auth state changes.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Ref<Object?> ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
