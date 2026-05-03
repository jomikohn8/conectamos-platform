// ignore_for_file: deprecated_member_use
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/flows_api.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// Key compuesta: slug + rango de fechas opcional (Dart record → == y hashCode automáticos)
typedef _DashKey = ({String slug, String? start, String? end});

/// Carga la lista de dashboards desde API.
final dashboardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return FlowsApi.listDashboardConfigurations();
});

/// Rango de fechas seleccionado. null = hoy (sin filtro explícito)
final dashboardDateRangeProvider = StateProvider<DateTimeRange?>((ref) => null);

final dashboardKpisProvider =
    FutureProvider.family<Map<String, dynamic>, _DashKey>((ref, key) async {
  return FlowsApi.getDashboardKpis(
    key.slug,
    dateRangeStart: key.start,
    dateRangeEnd: key.end,
  );
});

final dashboardChartsProvider =
    FutureProvider.family<Map<String, dynamic>, _DashKey>((ref, key) async {
  return FlowsApi.getDashboardCharts(
    key.slug,
    dateRangeStart: key.start,
    dateRangeEnd: key.end,
  );
});

final dashboardActivityProvider =
    FutureProvider.family<List<Map<String, dynamic>>, _DashKey>((ref, key) async {
  return FlowsApi.getDashboardActivity(
    key.slug,
    dateRangeStart: key.start,
    dateRangeEnd: key.end,
  );
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
    final range = ref.watch(dashboardDateRangeProvider);

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
          const Expanded(
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
          _DateRangeButton(
            range: range,
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
                initialDateRange: ref.read(dashboardDateRangeProvider),
              );
              if (picked != null) {
                ref.read(dashboardDateRangeProvider.notifier).state = picked;
              }
            },
            onClear: () =>
                ref.read(dashboardDateRangeProvider.notifier).state = null,
          ),
          const SizedBox(width: 8),
          _RefreshButton(
            onTap: () {
              ref.invalidate(dashboardKpisProvider);
              ref.invalidate(dashboardChartsProvider);
              ref.invalidate(dashboardActivityProvider);
              ref.invalidate(dashboardsProvider);
            },
          ),
        ],
      ),
    );
  }
}

// ── Date range button ─────────────────────────────────────────────────────────

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.range,
    required this.onTap,
    required this.onClear,
  });
  final DateTimeRange? range;
  final VoidCallback onTap;
  final VoidCallback onClear;

  String get _label {
    if (range == null) return 'Hoy';
    String pad(int n) => n.toString().padLeft(2, '0');
    final s = range!.start;
    final e = range!.end;
    return '${pad(s.day)}/${pad(s.month)} – ${pad(e.day)}/${pad(e.month)}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded,
                size: 12, color: AppColors.ctText2),
            const SizedBox(width: 6),
            Text(
              _label,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText2,
              ),
            ),
            if (range != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close_rounded,
                    size: 12, color: AppColors.ctText2),
              ),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 14, color: AppColors.ctText2),
            ],
          ],
        ),
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
    List<Map<String, dynamic>> activityData,
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
        activityData: activityData,
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

    String? activeHint; // 'kpi_row' | 'chart_row' | null

    for (final w in sortedWidgets) {
      final config = (w['config'] as Map<String, dynamic>?) ?? {};
      final hint = config['layout_hint'] as String?;
      if (hint == 'kpi_row' || hint == 'chart_row') {
        if (hint != activeHint && buffer.isNotEmpty) {
          // Different group type — flush before starting new buffer
          flushBuffer();
        }
        activeHint = hint;
        buffer.add(w);
      } else {
        flushBuffer();
        activeHint = null;
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
    final range = ref.watch(dashboardDateRangeProvider);
    String? start;
    String? end;
    if (range != null) {
      start = range.start.toUtc().toIso8601String();
      end = range.end.toUtc()
          .add(const Duration(hours: 23, minutes: 59, seconds: 59))
          .toIso8601String();
    }
    final key = (slug: slug, start: start, end: end);

    final asyncKpis = ref.watch(dashboardKpisProvider(key));
    final kpis = asyncKpis.valueOrNull ?? <String, dynamic>{};
    final asyncCharts = ref.watch(dashboardChartsProvider(key));
    final charts = asyncCharts.valueOrNull ?? <String, dynamic>{};
    final asyncActivity = ref.watch(dashboardActivityProvider(key));
    final activityData = asyncActivity.valueOrNull ?? <Map<String, dynamic>>[];

    final widgets = (dashboard['widgets'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    widgets.sort((a, b) =>
        ((a['position'] as num?) ?? 0).compareTo((b['position'] as num?) ?? 0));

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows =
            _buildRows(widgets, kpis, charts, activityData, constraints.maxWidth);
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
    this.activityData,
  });
  final Map<String, dynamic> widgetConfig;
  final Map<String, dynamic>? kpiData;
  final Map<String, dynamic>? chartData;
  final List<Map<String, dynamic>>? activityData;

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
        return _RecentActivityWidget(
            title: title, config: config, activityData: activityData);
      case 'bar_chart':
        return _BarChartWidget(title: title, config: config, chartData: chartData);
      case 'operator_ranking':
        return _OperatorRankingWidget(
            title: title, config: config, chartData: chartData);
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
    final colorKey =
        kpiData?['color'] as String? ?? config['color'] as String? ?? 'default';
    switch (colorKey) {
      case 'green':
        return AppColors.ctOk;
      case 'red':
        return AppColors.ctDanger;
      case 'amber':
        return AppColors.ctWarn;
      default:
        return AppColors.ctTeal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = kpiData?['value'];
    final label =
        kpiData?['label'] as String? ?? config['label'] as String? ?? '';
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
  const _RecentActivityWidget({
    required this.title,
    required this.config,
    this.activityData,
  });
  final String title;
  final Map<String, dynamic> config;
  final List<Map<String, dynamic>>? activityData;

  String _formatTime(String? isoString) {
    if (isoString == null) return '—';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return '—';
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = activityData ?? [];

    if (items.isEmpty) {
      return _DashCard(
        title: title.toUpperCase(),
        child: const _ComingSoonChip(),
      );
    }

    return _DashCard(
      title: title.toUpperCase(),
      child: Column(
        children: items.map((item) {
          final isDelivery = item['is_delivery'] as bool? ?? true;
          final operatorName = item['operator_name'] as String? ?? '—';
          final orderNumber = item['order_number'] as String? ?? '—';
          final completedAt = item['completed_at'] as String?;

          return GestureDetector(
            onTap: () {
                final executionId = item['execution_id'] as String?;
                if (executionId != null) {
                  context.go('/executions/$executionId');
                }
              },
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ctSurface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDelivery
                      ? AppColors.ctOk.withOpacity(0.3)
                      : AppColors.ctDanger.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDelivery ? AppColors.ctOk : AppColors.ctDanger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          operatorName,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.ctText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Orden #$orderNumber',
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        isDelivery ? 'Entregado' : 'Fallido',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDelivery ? AppColors.ctOk : AppColors.ctDanger,
                        ),
                      ),
                      Text(
                        _formatTime(completedAt),
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          color: AppColors.ctText2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.ctText2,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── bar_chart (pie chart) ─────────────────────────────────────────────────────

class _BarChartWidget extends StatefulWidget {
  const _BarChartWidget({
    required this.title,
    required this.config,
    this.chartData,
  });
  final String title;
  final Map<String, dynamic> config;
  final Map<String, dynamic>? chartData;

  @override
  State<_BarChartWidget> createState() => _BarChartWidgetState();
}

class _BarChartWidgetState extends State<_BarChartWidget> {
  int _touchedIndex = -1;

  static const _colors = [
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFF06B6D4),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final subtitle = widget.config['subtitle'] as String?;
    final data = (widget.chartData?['data'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (data.isEmpty) {
      return _DashCard(
        title: widget.title.toUpperCase(),
        subtitle: subtitle,
        child: const _ComingSoonChip(),
      );
    }

    final total = data.fold<double>(
        0, (s, e) => s + (e['value'] as num).toDouble());

    final sections = data.asMap().entries.map((entry) {
      final i = entry.key;
      final item = entry.value;
      final value = (item['value'] as num).toDouble();
      final isTouched = i == _touchedIndex;
      return PieChartSectionData(
        value: value,
        color: _colors[i % _colors.length],
        radius: isTouched ? 60 : 50,
        title: '',
        showTitle: false,
      );
    }).toList();

    return _DashCard(
      title: widget.title.toUpperCase(),
      subtitle: subtitle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: 160,
            width: 160,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          response.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: data.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
                final label = item['label'] as String? ?? '';
                final value = (item['value'] as num).toDouble();
                final pct = total > 0 ? (value / total * 100).round() : 0;
                final isSelected = i == _touchedIndex;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _colors[i % _colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: isSelected ? 12 : 11,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: AppColors.ctText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _colors[i % _colors.length],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
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

// ── Refresh button ────────────────────────────────────────────────────────────

class _RefreshButton extends ConsumerStatefulWidget {
  const _RefreshButton({required this.onTap});
  final VoidCallback onTap;

  @override
  ConsumerState<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends ConsumerState<_RefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder2),
        ),
        child: RotationTransition(
          turns: CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
          child: const Icon(
            Icons.refresh_rounded,
            size: 14,
            color: AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}
