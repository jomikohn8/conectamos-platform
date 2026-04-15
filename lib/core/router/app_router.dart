import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../../features/auth/activate_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/broadcasts/broadcast_screen.dart';
import '../../features/config/connections_screen.dart';
import '../../features/config/operators_screen.dart';
import '../../features/config/settings_screen.dart';
import '../../features/config/whatsapp_config_screen.dart';
import '../../features/config/workflows_screen.dart';
import '../../features/conversations/conversations_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/overview/overview_screen.dart';
import '../../features/sessions/sessions_screen.dart';
import '../../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/overview',
    redirect: (context, state) {
      if (kMockMode) {
        if (state.matchedLocation == '/login') return null;
        if (state.matchedLocation == '/overview') return null;
        if (state.matchedLocation == '/') return '/overview';
        return '/overview';
      }

      final user = Supabase.instance.client.auth.currentUser;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isActivating = loc.startsWith('/activate');

      // /activate es siempre pública
      if (isActivating) return null;

      // Redirect bare / to /overview
      if (loc == '/') return '/overview';

      if (user == null && !isLoggingIn) return '/login';
      if (user != null && isLoggingIn) return '/overview';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/activate',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return NoTransitionPage(child: ActivateScreen(token: token));
        },
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => NoTransitionPage(
          child: AppShell(child: child),
        ),
        routes: [
          GoRoute(
            path: '/overview',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OverviewScreen(),
            ),
          ),
          GoRoute(
            path: '/conversations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConversationsScreen(),
            ),
          ),
          GoRoute(
            path: '/broadcast',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: BroadcastScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/operators',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OperatorsScreen(),
            ),
          ),
          GoRoute(
            path: '/flows',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkflowsScreen(),
            ),
          ),
          GoRoute(
            path: '/connections',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConnectionsScreen(),
            ),
          ),
          GoRoute(
            path: '/connections/whatsapp',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WhatsAppConfigScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/sessions/:operatorName',
            pageBuilder: (context, state) {
              final name = Uri.decodeComponent(
                state.pathParameters['operatorName'] ?? '',
              );
              return NoTransitionPage(child: SessionsScreen(operatorName: name));
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.error}'),
      ),
    ),
  );
});
