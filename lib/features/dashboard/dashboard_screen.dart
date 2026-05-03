// ignore_for_file: deprecated_member_use
// ignore: unused_import
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/flows_api.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Carga la lista de dashboards desde API.
final dashboardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FlowsApi.listDashboardConfigurations();
});

final dashboardKpisProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, dashboardSlug) async {
  return FlowsApi.getDashboardKpis(dashboardSlug);
});

/// Fecha seleccionada para filtros (today / yesterday / 7days)
final dashboardDateFilterProvider = StateProvider<String>((ref) => 'today');

/// Charts data por dashboard slug
final dashboardChartsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, dashboardSlug) async {
  return FlowsApi.getDashboardCharts(dashboardSlug);
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

class _ActionBar extends ConsumerWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(dashboardDateFilterProvider);
    final subtitle = filter == 'yesterday'
        ? 'Datos de ayer'
        : filter == '7days'
            ? 'Últimos 7 días'
            : 'Panel operativo · actualiza cada 45s';
    final filterLabel = filter == 'yesterday'
        ? 'Ayer'
        : filter == '7days'
            ? '7 días'
            : 'Hoy';

    return Container(
      height: 48,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(subtitle, style: AppTextStyles.pageSubtitle),
              ],
            ),
          ),
          PopupMenuButton<String>(
            initialValue: filter,
            onSelected: (value) =>
                ref.read(dashboardDateFilterProvider.notifier).state = value,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'today',     child: Text('Hoy')),
              PopupMenuItem(value: 'yesterday', child: Text('Ayer')),
              PopupMenuItem(value: '7days',     child: Text('7 días')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ctBorder2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    filterLabel,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ctText2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: AppColors.ctText2,
                  ),
                ],
              ),
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
  });
  final String label;
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

class _ConfiguredView extends ConsumerWidget {
  const _ConfiguredView({required this.dashboard});
  final Map<String, dynamic> dashboard;

  List<Widget> _buildRows(
    List<Map<String, dynamic>> sortedWidgets,
    Map<String, dynamic> kpis,
    Map<String, dynamic> charts,
    double maxWidth,
  ) {
    final result = <Widget>[];
    final buffer = <Map<String, dynamic>>[];

    Widget rendererFor(Map<String, dynamic> w) {
      final id = w['id'] as String? ?? '';
      return _DashboardWidgetRenderer(
        widgetConfig: w,
        kpiData: kpis[id] as Map<String, dynamic>?,
        chartData: charts[id] as Map<String, dynamic>?,
      );
    }

    void flushBuffer() {
      if (buffer.isEmpty) return;
      Widget rowWidget;
      if (buffer.length == 1) {
        rowWidget = rendererFor(buffer.first);
      } else if (maxWidth < 600) {
        rowWidget = Column(
          children: buffer
              .map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: rendererFor(w),
                  ))
              .toList(),
        );
      } else {
        final children = <Widget>[];
        for (int i = 0; i < buffer.length; i++) {
          children.add(Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < buffer.length - 1 ? 12 : 0),
              child: rendererFor(buffer[i]),
            ),
          ));
        }
        rowWidget = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      }
      result.add(Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: rowWidget,
      ));
      buffer.clear();
    }

    for (final w in sortedWidgets) {
      final config = (w['config'] as Map<String, dynamic>?) ?? {};
      final hint = config['layout_hint'] as String?;
      if (hint == 'kpi_row') {
        buffer.add(w);
      } else {
        flushBuffer();
        result.add(Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: rendererFor(w),
        ));
      }
    }
    flushBuffer();

    return result;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slug = dashboard['slug'] as String? ?? '';
    final asyncKpis = ref.watch(dashboardKpisProvider(slug));
    final kpis = asyncKpis.valueOrNull ?? <String, dynamic>{};
    final asyncCharts = ref.watch(dashboardChartsProvider(slug));
    final charts = asyncCharts.valueOrNull ?? <String, dynamic>{};

    final widgets = (dashboard['widgets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    widgets.sort((a, b) =>
        ((a['position'] as num?) ?? 0).compareTo((b['position'] as num?) ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _buildRows(widgets, kpis, charts, constraints.maxWidth);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              ...rows,
            ],
          ),
        );
      },
    );
  }
}

// ── Renderer de widget individual ─────────────────────────────────────────────

class _DashboardWidgetRenderer extends StatelessWidget {
  const _DashboardWidgetRenderer({
    required this.widgetConfig,
    this.kpiData,
    this.chartData,
  });
  final Map<String, dynamic> widgetConfig;
  final Map<String, dynamic>? kpiData;
  final Map<String, dynamic>? chartData;

  @override
  Widget build(BuildContext context) {
    final type = widgetConfig['widget_type'] as String? ?? '';
    final title = widgetConfig['title'] as String? ?? '';
    final config = (widgetConfig['config'] as Map<String, dynamic>?) ?? {};

    switch (type) {
      case 'kpi_card':
        return _KpiCardWidget(title: title, config: config, kpiData: kpiData);
      case 'execution_table':
        return _ExecutionTableWidget(title: title, config: config);
      case 'operator_status_grid':
        return _OperatorGridWidget(title: title, config: config);
      case 'flow_action_button':
        return _FlowActionButton(title: title, config: config);
      case 'recent_activity_feed':
        return _RecentActivityWidget(title: title, config: config);
      case 'bar_chart':
        return _BarChartWidget(title: title, config: config, chartData: chartData);
      case 'operator_ranking':
        return _OperatorRankingWidget(title: title, config: config, chartData: chartData);
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
  const _KpiCardWidget({
    required this.title,
    required this.config,
    this.kpiData,
  });
  final String title;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? kpiData;

  Color _accentColor() {
    final colorKey = kpiData?['color'] as String? ?? config['color'] as String? ?? 'default';
    switch (colorKey) {
      case 'green': return AppColors.ctOk;
      case 'red':   return AppColors.ctDanger;
      case 'amber': return AppColors.ctWarn;
      default:      return AppColors.ctTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = kpiData?['value'];
    final label = kpiData?['label'] as String? ?? config['label'] as String? ?? '';
    final displayValue = value != null ? value.toString() : '—';
    final color = _accentColor();

    return _DashCard(
      title: title.toUpperCase(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            displayValue,
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

// ── bar_chart ─────────────────────────────────────────────────────────────────

class _BarChartWidget extends StatelessWidget {
  const _BarChartWidget({
    required this.title,
    required this.config,
    this.chartData,
  });
  final String title;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? chartData;

  @override
  Widget build(BuildContext context) {
    final subtitle = config['subtitle'] as String?;
    final data = (chartData?['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (data.isEmpty) {
      return _DashCard(
        title: title.toUpperCase(),
        subtitle: subtitle,
        child: const _ComingSoonChip(),
      );
    }

    final maxVal = data
        .map((e) => (e['value'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);

    return _DashCard(
      title: title.toUpperCase(),
      subtitle: subtitle,
      child: Column(
        children: data.map((item) {
          final label = item['label'] as String? ?? '';
          final value = (item['value'] as num).toDouble();
          final pct = maxVal > 0 ? value / maxVal : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: AppColors.ctText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 6,
                    backgroundColor: AppColors.ctSurface2,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.ctDanger),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── operator_ranking ──────────────────────────────────────────────────────────

class _OperatorRankingWidget extends StatelessWidget {
  const _OperatorRankingWidget({
    required this.title,
    required this.config,
    this.chartData,
  });
  final String title;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? chartData;

  @override
  Widget build(BuildContext context) {
    final subtitle = config['subtitle'] as String?;
    final data = (chartData?['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (data.isEmpty) {
      return _DashCard(
        title: title.toUpperCase(),
        subtitle: subtitle,
        child: const _ComingSoonChip(),
      );
    }

    return _DashCard(
      title: title.toUpperCase(),
      subtitle: subtitle,
      child: Column(
        children: data.map((item) {
          final rank = item['rank'] as int? ?? 0;
          final name = item['name'] as String? ?? '';
          final rate = (item['value'] as num).toDouble();
          final total = item['total'] as int? ?? 0;
          final numerator = item['numerator'] as int? ?? 0;

          final medal = rank == 1
              ? '🥇'
              : rank == 2
                  ? '🥈'
                  : rank == 3
                      ? '🥉'
                      : '#$rank';
          final color = rate >= 80
              ? AppColors.ctOk
              : rate >= 60
                  ? AppColors.ctWarn
                  : AppColors.ctDanger;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(medal, style: const TextStyle(fontSize: 14)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ctText,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          minHeight: 5,
                          backgroundColor: AppColors.ctSurface2,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${rate.toInt()}%',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Text(
                      '$numerator/$total',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
