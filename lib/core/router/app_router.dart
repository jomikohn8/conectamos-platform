import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../../features/auth/activate_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/config/meta_credentials_screen.dart';
import '../../features/config/operators_screen.dart';
import '../../features/config/whatsapp_groups_screen.dart';
import '../../features/config/workflows_screen.dart';
import '../../features/conversations/conversations_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/overview/overview_screen.dart';
import '../../features/sessions/sessions_screen.dart';
import '../../shared/widgets/app_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // En modo mock: /login y / son accesibles directamente;
      // cualquier otra ruta va a /.
      if (kMockMode) {
        if (state.matchedLocation == '/login') return null;
        if (state.matchedLocation == '/') return null;
        return '/';
      }

      final user = Supabase.instance.client.auth.currentUser;
      final loc = state.matchedLocation;
      final isLoggingIn = loc == '/login';
      final isActivating = loc.startsWith('/activate');

      // /activate es siempre pública — nunca redirigir, logueado o no
      if (isActivating) return null;

      if (user == null && !isLoggingIn) return '/login';
      if (user != null && isLoggingIn) return '/';
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
          final token =
              state.uri.queryParameters['token'] ?? '';
          return ActivateScreen(token: token);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const OverviewScreen(),
          ),
          GoRoute(
            path: '/conversaciones',
            builder: (context, state) => const ConversationsScreen(),
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/config/meta',
            builder: (context, state) => const MetaCredentialsScreen(),
          ),
          GoRoute(
            path: '/config/operadores',
            builder: (context, state) => const OperatorsScreen(),
          ),
          GoRoute(
            path: '/config/flujos',
            builder: (context, state) => const WorkflowsScreen(),
          ),
          GoRoute(
            path: '/config/grupos',
            builder: (context, state) => const WhatsAppGroupsScreen(),
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
