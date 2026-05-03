// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/flows_api.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Carga la lista de dashboards desde API.
final dashboardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FlowsApi.listDashboardConfigurations();
});

// ── Pantalla ──────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        _ActionBar(),
        Expanded(child: _DashboardBody()),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Panel operativo · actualiza cada 45s',
                  style: AppTextStyles.pageSubtitle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ghost button (reservado para uso futuro) ──────────────────────────────────

class _GhostButton extends StatefulWidget {
  const _GhostButton({
    required this.label,
    required this.onTap,
    this.icon,
  });
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: AppColors.ctText2),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Cuerpo principal ──────────────────────────────────────────────────────────

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDashboards = ref.watch(dashboardsProvider);
    return asyncDashboards.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.ctTeal),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error al cargar dashboard',
          style: AppTextStyles.pageSubtitle,
        ),
      ),
      data: (dashboards) {
        if (dashboards.isEmpty) return const _EmptyView();
        final dashboard = dashboards.firstWhere(
          (d) => d['is_default'] == true,
          orElse: () => dashboards.first,
        );
        return _ConfiguredView(dashboard: dashboard);
      },
    );
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.dashboard_outlined, size: 48, color: AppColors.ctText2),
          const SizedBox(height: 16),
          const Text(
            'Sin dashboard configurado',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Contacta a Conectamos para configurar\ntu panel operativo.',
            textAlign: TextAlign.center,
            style: AppTextStyles.pageSubtitle,
          ),
        ],
      ),
    );
  }
}

// ── Vista configurada ─────────────────────────────────────────────────────────

class _ConfiguredView extends StatelessWidget {
  const _ConfiguredView({required this.dashboard});
  final Map<String, dynamic> dashboard;

  @override
  Widget build(BuildContext context) {
    final widgets = (dashboard['widgets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    widgets.sort((a, b) =>
        ((a['position'] as num?) ?? 0).compareTo((b['position'] as num?) ?? 0));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre del dashboard
          Text(
            dashboard['name'] as String? ?? 'Dashboard',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 20),

          // Grid de widgets
          ...widgets.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _DashboardWidgetRenderer(widgetConfig: w),
          )),
        ],
      ),
    );
  }
}

// ── Renderer de widget individual ─────────────────────────────────────────────

class _DashboardWidgetRenderer extends StatelessWidget {
  const _DashboardWidgetRenderer({required this.widgetConfig});
  final Map<String, dynamic> widgetConfig;

  @override
  Widget build(BuildContext context) {
    final type = widgetConfig['widget_type'] as String? ?? '';
    final title = widgetConfig['title'] as String? ?? '';
    final config = (widgetConfig['config'] as Map<String, dynamic>?) ?? {};

    switch (type) {
      case 'kpi_card':
        return _KpiCardWidget(title: title, config: config);
      case 'execution_table':
        return _ExecutionTableWidget(title: title, config: config);
      case 'operator_status_grid':
        return _OperatorGridWidget(title: title, config: config);
      case 'flow_action_button':
        return _FlowActionButton(title: title, config: config);
      case 'recent_activity_feed':
        return _RecentActivityWidget(title: title, config: config);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ── Widget base card ──────────────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({required this.title, this.subtitle, required this.child});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.ctBorder),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText2,
              letterSpacing: 0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTextStyles.pageSubtitle),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── kpi_card ──────────────────────────────────────────────────────────────────

class _KpiCardWidget extends StatelessWidget {
  const _KpiCardWidget({required this.title, required this.config});
  final String title;
  final Map<String, dynamic> config;

  Color _accentColor() {
    switch (config['color'] as String? ?? 'default') {
      case 'green': return AppColors.ctOk;
      case 'red':   return AppColors.ctDanger;
      case 'amber': return AppColors.ctWarn;
      default:      return AppColors.ctTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = config['label'] as String? ?? '';
    final color = _accentColor();
    return _DashCard(
      title: title.toUpperCase(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '—',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── execution_table ───────────────────────────────────────────────────────────

class _ExecutionTableWidget extends StatelessWidget {
  const _ExecutionTableWidget({required this.title, required this.config});
  final String title;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final subtitle = config['subtitle'] as String?;
    return _DashCard(
      title: title.toUpperCase(),
      subtitle: subtitle,
      child: const _ComingSoonChip(),
    );
  }
}

// ── operator_status_grid ──────────────────────────────────────────────────────

class _OperatorGridWidget extends StatelessWidget {
  const _OperatorGridWidget({required this.title, required this.config});
  final String title;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final subtitle = config['subtitle'] as String?;
    return _DashCard(
      title: title.toUpperCase(),
      subtitle: subtitle,
      child: const _ComingSoonChip(),
    );
  }
}

// ── flow_action_button ────────────────────────────────────────────────────────

class _FlowActionButton extends StatelessWidget {
  const _FlowActionButton({required this.title, required this.config});
  final String title;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    final label = config['label'] as String? ?? title;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: null, // Sprint siguiente: disparar flow
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ctTeal,
          foregroundColor: AppColors.ctNavy,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ── recent_activity_feed ──────────────────────────────────────────────────────

class _RecentActivityWidget extends StatelessWidget {
  const _RecentActivityWidget({required this.title, required this.config});
  final String title;
  final Map<String, dynamic> config;

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      title: title.toUpperCase(),
      child: const _ComingSoonChip(),
    );
  }
}

// ── Placeholder chip ──────────────────────────────────────────────────────────

class _ComingSoonChip extends StatelessWidget {
  const _ComingSoonChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Datos en tiempo real — próximo sprint',
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          color: AppColors.ctText2,
        ),
      ),
    );
  }
}
