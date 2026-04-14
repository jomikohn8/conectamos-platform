import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../../features/auth/activate_screen.dart';
import '../../features/auth/login_screen.dart';
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ActivateScreen(token: token);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/overview',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/conversations',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/operators',
            builder: (context, state) => const OperatorsScreen(),
          ),
          GoRoute(
            path: '/flows',
            builder: (context, state) => const WorkflowsScreen(),
          ),
          GoRoute(
            path: '/connections',
            builder: (context, state) => const ConnectionsScreen(),
          ),
          GoRoute(
            path: '/connections/whatsapp',
            builder: (context, state) => const WhatsAppConfigScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/sessions/:operatorName',
            builder: (context, state) {
              final name = Uri.decodeComponent(
                state.pathParameters['operatorName'] ?? '',
              );
              return SessionsScreen(operatorName: name);
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
