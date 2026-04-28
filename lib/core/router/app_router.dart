import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';
import '../providers/permissions_provider.dart';
import '../../features/auth/activate_screen.dart';
import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/broadcasts/broadcast_screen.dart';
import '../../features/config/channel_detail_screen.dart';
import '../../features/config/channels_screen.dart';
import '../../features/config/connections_screen.dart';
import '../../features/config/operator_detail_screen.dart';
import '../../features/config/operators_screen.dart';
import '../../features/config/settings_screen.dart';
import '../../features/settings/operator_fields_screen.dart';
import '../../features/config/ai_workers_screen.dart';
import '../../features/config/workflows_screen.dart';
import '../../features/flows/executions_screen.dart';
import '../../features/flows/flow_detail_screen.dart';
import '../../features/conversations/conversations_screen.dart';
import '../../features/dashboard/dashboard_screen.dart';
import '../../features/overview/overview_screen.dart';
import '../../shared/widgets/app_shell.dart';

// Mapa de ruta → permiso requerido
const _kRoutePermissions = {
  '/operators':   'operators.view',
  '/flows':       'flows.view',
  '/channels':    'settings.view',
  '/connections': 'settings.view',
  '/settings':    'settings.view',
  '/broadcast':   'broadcasts.send',
};

final routerProvider = Provider<GoRouter>((ref) {
  // Refresca el router cuando cargan los permisos
  final refresher = ValueNotifier<int>(0);
  ref.listen(userPermissionsProvider, (prev, next) => refresher.value++);

  return GoRouter(
    initialLocation: '/overview',
    refreshListenable: refresher,
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
      final isPublicAuth = loc == '/forgot-password' || loc.startsWith('/reset-password');

      // Rutas de auth públicas
      if (isActivating || isPublicAuth) return null;

      // Redirect bare / to /overview
      if (loc == '/') return '/overview';

      if (user == null && !isLoggingIn) return '/login';
      if (user != null && isLoggingIn) return '/overview';

      // Guard de permisos (solo cuando ya cargaron)
      final perms = ref.read(userPermissionsProvider).valueOrNull;
      if (perms != null) {
        for (final entry in _kRoutePermissions.entries) {
          if (loc.startsWith(entry.key) && !perms.contains(entry.value)) {
            return '/overview';
          }
        }
      }

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
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return NoTransitionPage(child: ResetPasswordScreen(token: token));
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
            path: '/tareas',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExecutionsScreen(),
            ),
          ),
          GoRoute(
            path: '/flows',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WorkflowsScreen(),
            ),
          ),
          GoRoute(
            path: '/flows/:flowId',
            pageBuilder: (context, state) {
              final flowId = state.pathParameters['flowId'] ?? '';
              return NoTransitionPage(child: FlowDetailScreen(flowId: flowId));
            },
          ),
          GoRoute(
            path: '/workers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: AiWorkersScreen(),
            ),
          ),
          GoRoute(
            path: '/channels',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ChannelsScreen(),
            ),
          ),
          GoRoute(
            path: '/channels/:channelId',
            pageBuilder: (context, state) {
              final channelId = state.pathParameters['channelId'] ?? '';
              return NoTransitionPage(
                child: ChannelDetailScreen(channelId: channelId),
              );
            },
          ),
          GoRoute(
            path: '/connections',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ConnectionsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: '/settings/operator-fields',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OperatorFieldsScreen(),
            ),
          ),
          GoRoute(
            path: '/operators/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id'] ?? '';
              return NoTransitionPage(
                  child: OperatorDetailScreen(operatorId: id));
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
