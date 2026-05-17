import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/messaging/presentation/screens/chat_screen.dart';
import '../features/messaging/presentation/screens/conversations_screen.dart';
import '../features/notifications/presentation/screens/notifications_screen.dart';
import '../features/tickets/presentation/screens/tickets_screen.dart';
import '../shared/screens/home_screen.dart';
import '../shared/screens/profile_screen.dart';
import '../admin_panel/dashboard/screens/admin_dashboard_screen.dart';
import '../admin_panel/users/screens/admin_users_screen.dart';
import '../admin_panel/analytics/screens/admin_analytics_screen.dart';
import 'main_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/home',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.isAuthenticated;
      final isLoginRoute = state.matchedLocation.startsWith('/login') || state.matchedLocation.startsWith('/register');
      final isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (isLoading) return null;
      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/home';
      if (isAdminRoute && !(authState.user?.isAdmin ?? false) && !(authState.user?.isModerator ?? false)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Main App Shell
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child, location: state.matchedLocation),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/home/messages', builder: (_, __) => const ConversationsScreen()),
          GoRoute(path: '/home/chat/:id', builder: (_, state) => ChatScreen(conversationId: state.pathParameters['id']!)),
          GoRoute(path: '/home/notifications', builder: (_, __) => const NotificationsScreen()),
          GoRoute(path: '/home/tickets', builder: (_, __) => const TicketsScreen()),
          GoRoute(path: '/home/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Admin Shell
      GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/users', builder: (_, __) => const AdminUsersScreen()),
      GoRoute(path: '/admin/analytics', builder: (_, __) => const AdminAnalyticsScreen()),
      GoRoute(path: '/admin/groups', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/tickets', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/moderation', builder: (_, __) => const AdminDashboardScreen()),
      GoRoute(path: '/admin/settings', builder: (_, __) => const AdminDashboardScreen()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('الصفحة غير موجودة: ${state.error}')),
    ),
  );
});
