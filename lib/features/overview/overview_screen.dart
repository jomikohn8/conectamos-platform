import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../core/api/operators_api.dart';
import '../../core/api/overview_api.dart';
import '../../core/config.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Modelos de datos ──────────────────────────────────────────────────────────

class FlowBadgeData {
  const FlowBadgeData({
    required this.label,
    required this.bg,
    required this.textColor,
  });
  final String label;
  final Color bg;
  final Color textColor;
}

class OperatorData {
  const OperatorData({
    required this.name,
    required this.phone,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.statusLabel,
    required this.statusBg,
    required this.statusTextColor,
    required this.flows,
    required this.footerText,
  });
  final String name;
  final String phone;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String statusLabel;
  final Color statusBg;
  final Color statusTextColor;
  final List<FlowBadgeData> flows;
  final String footerText;
}

// ── Datos mock (solo para kMockMode) ─────────────────────────────────────────

const _kOperators = [
  OperatorData(
    name: 'Roberto Medina',
    phone: '+52 55 1234 5678',
    initials: 'RM',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    statusLabel: 'Activo',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    flows: [
      FlowBadgeData(
        label: 'Flujo 1: Turno ✓',
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      ),
      FlowBadgeData(
        label: 'Flujo 2: 3 IDs',
        bg: AppColors.ctTealLight,
        textColor: AppColors.ctTealDark,
      ),
    ],
    footerText: 'Último evento: hace 4 min',
  ),
  OperatorData(
    name: 'Jorge López',
    phone: '+52 55 9876 5432',
    initials: 'JL',
    avatarBg: AppColors.ctWarnBg,
    avatarTextColor: AppColors.ctWarnText,
    statusLabel: 'En espera',
    statusBg: AppColors.ctWarnBg,
    statusTextColor: AppColors.ctWarnText,
    flows: [
      FlowBadgeData(
        label: 'Flujo 1: Turno ✓',
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      ),
      FlowBadgeData(
        label: 'Flujo 2: 4 IDs',
        bg: AppColors.ctTealLight,
        textColor: AppColors.ctTealDark,
      ),
    ],
    footerText: 'Último evento: hace 18 min',
  ),
  OperatorData(
    name: 'Miguel Herrera',
    phone: '+52 55 5555 1234',
    initials: 'MH',
    avatarBg: AppColors.ctRedBg,
    avatarTextColor: AppColors.ctRedText,
    statusLabel: 'Incidencia',
    statusBg: AppColors.ctRedBg,
    statusTextColor: AppColors.ctRedText,
    flows: [
      FlowBadgeData(
        label: 'Flujo 1: Turno ✓',
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      ),
      FlowBadgeData(
        label: 'Flujo 3: alerta activa',
        bg: AppColors.ctRedBg,
        textColor: AppColors.ctRedText,
      ),
    ],
    footerText: '⚠ Sin actualización · 32 min',
  ),
  OperatorData(
    name: 'Andrés Pérez',
    phone: '+52 55 6677 8899',
    initials: 'AP',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    statusLabel: 'Activo',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    flows: [
      FlowBadgeData(
        label: 'Flujo 1: Turno ✓',
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      ),
      FlowBadgeData(
        label: 'Flujo 2: 3 IDs',
        bg: AppColors.ctTealLight,
        textColor: AppColors.ctTealDark,
      ),
    ],
    footerText: 'Último evento: hace 11 min',
  ),
  OperatorData(
    name: 'Luis Castro',
    phone: '+52 55 4433 2211',
    initials: 'LC',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    statusLabel: 'Activo',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    flows: [
      FlowBadgeData(
        label: 'Flujo 1: Turno ✓',
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      ),
      FlowBadgeData(
        label: 'Flujo 2: 2 IDs',
        bg: AppColors.ctTealLight,
        textColor: AppColors.ctTealDark,
      ),
    ],
    footerText: 'Último evento: hace 7 min',
  ),
  OperatorData(
    name: 'Sara Ramos',
    phone: '+52 55 1122 3344',
    initials: 'SR',
    avatarBg: AppColors.ctSurface2,
    avatarTextColor: AppColors.ctText3,
    statusLabel: 'Sin inicio',
    statusBg: AppColors.ctSurface2,
    statusTextColor: AppColors.ctText2,
    flows: [
      FlowBadgeData(
        label: 'Sin actividad',
        bg: AppColors.ctSurface2,
        textColor: AppColors.ctText2,
      ),
    ],
    footerText: 'No ha iniciado turno · Asignado 08:00',
  ),
];

// ── Helpers para mapear datos de la API ───────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
  return name.substring(0, name.length >= 2 ? 2 : name.length).toUpperCase();
}

OperatorData _operatorFromApi(Map<String, dynamic> data) {
  final status = (data['status'] as String? ?? 'inactive').toLowerCase();
  final name = data['name'] as String? ?? '';
  final phone = data['phone'] as String? ?? '';
  final lastEventAt = data['last_event_at'] as String?;

  final Color avatarBg;
  final Color avatarTextColor;
  final String statusLabel;
  final Color statusBg;
  final Color statusTextColor;

  switch (status) {
    case 'active':
      avatarBg = AppColors.ctTealLight;
      avatarTextColor = AppColors.ctTealDark;
      statusLabel = 'Activo';
      statusBg = AppColors.ctOkBg;
      statusTextColor = AppColors.ctOkText;
    case 'incident':
      avatarBg = AppColors.ctRedBg;
      avatarTextColor = AppColors.ctRedText;
      statusLabel = 'Incidencia';
      statusBg = AppColors.ctRedBg;
      statusTextColor = AppColors.ctRedText;
    default:
      avatarBg = AppColors.ctSurface2;
      avatarTextColor = AppColors.ctText3;
      statusLabel = 'Inactivo';
      statusBg = AppColors.ctSurface2;
      statusTextColor = AppColors.ctText2;
  }

  final rawFlows = data['flows'];
  final List<FlowBadgeData> flows;
  if (rawFlows is List && rawFlows.isNotEmpty) {
    flows = rawFlows.map((f) {
      final label = f is Map ? (f['name'] ?? f['label'] ?? f.toString()) : f.toString();
      return FlowBadgeData(
        label: label as String,
        bg: AppColors.ctInfoBg,
        textColor: AppColors.ctInfoText,
      );
    }).toList();
  } else {
    flows = const [
      FlowBadgeData(
        label: 'Sin actividad',
        bg: AppColors.ctSurface2,
        textColor: AppColors.ctText2,
      ),
    ];
  }

  String footerText;
  if (lastEventAt == null) {
    footerText = 'Sin actividad';
  } else {
    try {
      final dt = DateTime.parse(lastEventAt).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        footerText = 'Último evento: ahora mismo';
      } else if (diff.inMinutes < 60) {
        footerText = 'Último evento: hace ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        footerText = 'Último evento: hace ${diff.inHours} h';
      } else {
        footerText = 'Último evento: hace ${diff.inDays} días';
      }
    } catch (_) {
      footerText = 'Sin actividad';
    }
  }

  return OperatorData(
    name: name,
    phone: phone,
    initials: _initials(name),
    avatarBg: avatarBg,
    avatarTextColor: avatarTextColor,
    statusLabel: statusLabel,
    statusBg: statusBg,
    statusTextColor: statusTextColor,
    flows: flows,
    footerText: footerText,
  );
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class OverviewScreen extends ConsumerStatefulWidget {
  const OverviewScreen({super.key});

  @override
  ConsumerState<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends ConsumerState<OverviewScreen> {
  Map<String, dynamic>? _kpis;
  bool _kpisLoading = false;
  bool _kpisError = false;
  bool _initialized = false;

  // List<dynamic> _executions = [];
  // bool _executionsLoading = false;
  // bool _executionsError = false;
  Timer? _refreshTimer;
  // DateTime? _lastExecutionsFetch;

  @override
  void initState() {
    super.initState();
    // Defer until after first frame so activeTenantIdProvider is populated.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId.isNotEmpty) _fetchKpis(tenantId);
      // If still empty, the ref.listen in build() will trigger the fetch.
    });
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return;
    //   final tenantId = ref.read(activeTenantIdProvider);
    //   if (tenantId.isNotEmpty) {
    //     _fetchExecutions(tenantId);
    //     _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
    //       final tid = ref.read(activeTenantIdProvider);
    //       if (tid.isNotEmpty) _fetchExecutions(tid);
    //     });
    //   }
    // });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchKpis(String tenantId) async {
    if (tenantId.isEmpty) return;
    setState(() {
      _kpisLoading = true;
      _kpisError = false;
    });
    try {
      final data = await OverviewApi.getKpis(tenantId: tenantId);
      setState(() {
        _kpis = data;
        _kpisLoading = false;
        _initialized = true;
      });
    } catch (_) {
      setState(() {
        _kpisLoading = false;
        _kpisError = true;
        _initialized = true;
      });
    }
  }

  // Future<void> _fetchExecutions(String tenantId) async {
  //   if (tenantId.isEmpty) return;
  //   setState(() { _executionsLoading = true; _executionsError = false; });
  //   try {
  //     final data = await OverviewApi.getFlowExecutionsDebug(tenantId: tenantId);
  //     setState(() {
  //       _executions = List<dynamic>.from(data['executions'] ?? []);
  //       _executionsLoading = false;
  //       _lastExecutionsFetch = DateTime.now();
  //     });
  //   } catch (_) {
  //     setState(() { _executionsLoading = false; _executionsError = true; });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(activeTenantIdProvider);

    // Catch the moment tenantId arrives (e.g. slow auth load).
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (next.isNotEmpty && !_initialized && !_kpisLoading) {
        _fetchKpis(next);
      }
      // if (next.isNotEmpty) {
      //   _fetchExecutions(next);
      //   _refreshTimer?.cancel();
      //   _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      //     final tid = ref.read(activeTenantIdProvider);
      //     if (tid.isNotEmpty) _fetchExecutions(tid);
      //   });
      // }
    });

    // While tenant is not yet resolved, show a full-screen spinner.
    if (tenantId.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _ActionBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _KpiRow(
                  kpis: _kpis,
                  loading: _kpisLoading,
                  error: _kpisError,
                ),
                // const SizedBox(height: 18),
                // _ExecutionsSection(
                //   executions: _executions,
                //   loading: _executionsLoading,
                //   error: _executionsError,
                //   onRefresh: () {
                //     final tid = ref.read(activeTenantIdProvider);
                //     if (tid.isNotEmpty) _fetchExecutions(tid);
                //   },
                //   lastFetch: _lastExecutionsFetch,
                // ),
                const SizedBox(height: 18),
                const Text(
                  'OPERADORES EN TURNO',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText3,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _OperatorGrid(tenantId: tenantId),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Barra de acciones ─────────────────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  const _ActionBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantName = ref.watch(activeTenantDisplayProvider);
    final subtitle = tenantName.isNotEmpty
        ? 'Hoy · $tenantName · Sistema operativo'
        : 'Hoy · Sistema operativo';

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
                Text(
                  'Vista general',
                  style: AppFonts.onest(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          const _DateButton(),
        ],
      ),
    );
  }
}

class _DateButton extends StatefulWidget {
  const _DateButton();

  @override
  State<_DateButton> createState() => _DateButtonState();
}

class _DateButtonState extends State<_DateButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final formatted = '$d/$m/${now.year}';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.ctBorder : AppColors.ctSurface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: AppColors.ctText,
            ),
            const SizedBox(width: 6),
            Text(
              '$formatted  ▾',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Fila de KPIs ─────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.kpis,
    required this.loading,
    required this.error,
  });

  final Map<String, dynamic>? kpis;
  final bool loading;
  final bool error;

  String _val(String key) {
    if (loading) return '...';
    if (error || kpis == null) return '—';
    return kpis![key]?.toString() ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final activeOps = loading ? null : (kpis?['operators_active'] as num?)?.toInt();
    final totalOps  = loading ? null : (kpis?['operators_total']  as num?)?.toInt();

    final opsValue = loading
        ? '...'
        : (error || kpis == null)
            ? '— / —'
            : '${activeOps ?? '—'} / ${totalOps ?? '—'}';

    final inactivos = (activeOps != null && totalOps != null)
        ? totalOps - activeOps
        : null;
    final opsSub = inactivos != null
        ? '$inactivos sin turno hoy'
        : 'Operadores en turno activo';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctTeal,
                label: 'OPERADORES ACTIVOS',
                value: opsValue,
                subtext: opsSub,
                hasError: error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctOk,
                label: 'FLUJOS ACTIVOS',
                value: _val('flows_active'),
                subtext: 'Flujos activos en curso',
                hasError: error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctWarn,
                label: 'FLUJOS COMPLETADOS HOY',
                value: _val('flows_completed_today'),
                subtext: 'Completados desde medianoche',
                hasError: error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctDanger,
                label: 'WORKERS CONTRATADOS',
                value: _val('workers_contracted'),
                subtext: 'Workers activos en tu operación',
                hasError: error,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── KpiCard ───────────────────────────────────────────────────────────────────

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.topBorderColor,
    required this.label,
    required this.value,
    required this.subtext,
    this.hasError = false,
  });

  final Color topBorderColor;
  final String label;
  final String value;
  final String subtext;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final valueWidget = hasError
        ? Tooltip(
            message: 'Error al cargar',
            child: Text(
              value,
              style: AppFonts.onest(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.ctText3,
                height: 1,
              ),
            ),
          )
        : Text(
            value,
            style: AppFonts.onest(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
              height: 1,
            ),
          );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: topBorderColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText2,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          valueWidget,
          const SizedBox(height: 5),
          Text(
            subtext,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              color: AppColors.ctText3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Grid de operadores ────────────────────────────────────────────────────────

class _OperatorGrid extends StatefulWidget {
  const _OperatorGrid({required this.tenantId});

  final String tenantId;

  @override
  State<_OperatorGrid> createState() => _OperatorGridState();
}

class _OperatorGridState extends State<_OperatorGrid> {
  bool _loading = false;
  String? _error;
  List<OperatorData> _operators = [];

  @override
  void initState() {
    super.initState();
    // Guard: only load when tenantId is available.
    if (widget.tenantId.isNotEmpty) _load();
  }

  @override
  void didUpdateWidget(_OperatorGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Tenant arrived after widget was first built with an empty id.
    if (oldWidget.tenantId.isEmpty && widget.tenantId.isNotEmpty) {
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.tenantId.isEmpty) return;
    if (kMockMode) {
      setState(() {
        _operators = _kOperators.toList();
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final raw = await OperatorsApi.listOperators(tenantId: widget.tenantId);
      setState(() {
        _operators = raw.map(_operatorFromApi).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ctRedBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctDanger),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.ctRedText, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error al cargar operadores: $_error',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctRedText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _load,
              child: const Text(
                'Reintentar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctRedText,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_operators.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No hay operadores registrados.',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText2,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 900 ? 3 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: cols == 3 ? 2.1 : 1.9,
          ),
          itemCount: _operators.length,
          itemBuilder: (context, i) => OperatorCard(operator: _operators[i]),
        );
      },
    );
  }
}

// ── OperatorCard ──────────────────────────────────────────────────────────────

class OperatorCard extends StatefulWidget {
  const OperatorCard({super.key, required this.operator});
  final OperatorData operator;

  @override
  State<OperatorCard> createState() => _OperatorCardState();
}

class _OperatorCardState extends State<OperatorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final op = widget.operator;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: AppColors.ctSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hovered ? AppColors.ctBorder2 : AppColors.ctBorder,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _OperatorAvatar(
                      initials: op.initials,
                      bg: op.avatarBg,
                      textColor: op.avatarTextColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            op.name,
                            style: AppFonts.onest(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ctText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            op.phone,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 10,
                              color: AppColors.ctText2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: op.statusLabel,
                      bg: op.statusBg,
                      textColor: op.statusTextColor,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: op.flows.map((f) => FlowBadge(data: f)).toList(),
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.ctBorder)),
                ),
                child: Text(
                  op.footerText,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    color: AppColors.ctText2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _OperatorAvatar ───────────────────────────────────────────────────────────

class _OperatorAvatar extends StatelessWidget {
  const _OperatorAvatar({
    required this.initials,
    required this.bg,
    required this.textColor,
  });
  final String initials;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppFonts.onest(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

// ── StatusBadge ───────────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.bg,
    required this.textColor,
  });
  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ── FlowBadge ─────────────────────────────────────────────────────────────────

class FlowBadge extends StatelessWidget {
  const FlowBadge({super.key, required this.data});
  final FlowBadgeData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        data.label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: data.textColor,
        ),
      ),
    );
  }
}

// ── Helpers para executions (comentado — sección movida a ExecutionsScreen) ───

// String _formatElapsed(int? seconds) {
//   if (seconds == null) return '—';
//   if (seconds < 60) return '${seconds}s';
//   if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
//   return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
// }
//
// String _elapsedSince(DateTime t) {
//   final diff = DateTime.now().difference(t);
//   if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
//   if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
//   return 'hace ${diff.inHours}h';
// }

// ── _ExecutionsSection (comentado — sección movida a ExecutionsScreen) ─────────

// class _ExecutionsSection extends StatelessWidget {
//   const _ExecutionsSection({
//     required this.executions,
//     required this.loading,
//     required this.error,
//     required this.onRefresh,
//     required this.lastFetch,
//   });
//
//   final List<dynamic> executions;
//   final bool loading;
//   final bool error;
//   final VoidCallback onRefresh;
//   final DateTime? lastFetch;
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Header
//         Row(
//           children: [
//             const Text(
//               'FLUJOS EN CURSO',
//               style: TextStyle(
//                 fontFamily: 'Geist',
//                 fontSize: 10,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.ctText3,
//                 letterSpacing: 1.2,
//               ),
//             ),
//             const SizedBox(width: 8),
//             Container(
//               padding:
//                   const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//               decoration: BoxDecoration(
//                 color: AppColors.ctTealLight,
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Text(
//                 '${executions.length}',
//                 style: const TextStyle(
//                   fontFamily: 'Geist',
//                   fontSize: 11,
//                   fontWeight: FontWeight.w600,
//                   color: AppColors.ctTealDark,
//                 ),
//               ),
//             ),
//             const Spacer(),
//             if (lastFetch != null)
//               Text(
//                 'Act. ${_elapsedSince(lastFetch!)}',
//                 style: const TextStyle(
//                   fontFamily: 'Geist',
//                   fontSize: 10,
//                   color: AppColors.ctText3,
//                 ),
//               ),
//             const SizedBox(width: 4),
//             SizedBox(
//               width: 30,
//               height: 30,
//               child: IconButton(
//                 padding: EdgeInsets.zero,
//                 icon: const Icon(Icons.refresh,
//                     size: 16, color: AppColors.ctText3),
//                 onPressed: onRefresh,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         // Body
//         if (loading && executions.isEmpty)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.all(24),
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           )
//         else if (error)
//           Center(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Error al cargar executions',
//                   style: TextStyle(
//                     fontFamily: 'Geist',
//                     fontSize: 13,
//                     color: AppColors.ctText3,
//                   ),
//                 ),
//                 TextButton(
//                   onPressed: onRefresh,
//                   child: const Text('Reintentar'),
//                 ),
//               ],
//             ),
//           )
//         else if (executions.isEmpty)
//           const Center(
//             child: Padding(
//               padding: EdgeInsets.all(24),
//               child: Text(
//                 'Sin executions registradas',
//                 style: TextStyle(
//                   fontFamily: 'Geist',
//                   fontSize: 13,
//                   color: AppColors.ctText3,
//                 ),
//               ),
//             ),
//           )
//         else
//           ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: executions.length,
//             itemBuilder: (context, i) => _ExecutionTile(
//               execution: executions[i] as Map<String, dynamic>,
//             ),
//           ),
//       ],
//     );
//   }
// }
//
// // ── _ExecutionTile ────────────────────────────────────────────────────────────
//
// class _ExecutionTile extends StatelessWidget {
//   const _ExecutionTile({required this.execution});
//
//   final Map<String, dynamic> execution;
//
//   @override
//   Widget build(BuildContext context) {
//     final flowDef = execution['flow_definition'] as Map<String, dynamic>?;
//     final operator_ = execution['operator'] as Map<String, dynamic>?;
//     final status = execution['status'] as String? ?? 'unknown';
//     final elapsedSeconds = execution['elapsed_seconds'] as int?;
//     final fieldsCaptured =
//         (execution['fields_captured'] as Map?)
//             ?.map((k, v) => MapEntry(k.toString(), v)) ??
//         <String, dynamic>{};
//
//     final fieldsExpected = flowDef != null
//         ? List<Map<String, dynamic>>.from(
//             (flowDef['fields_expected'] as List? ?? [])
//                 .map((f) => Map<String, dynamic>.from(f as Map)),
//           )
//         : <Map<String, dynamic>>[];
//
//     final captured = fieldsExpected.where((f) {
//       final v = fieldsCaptured[f['key']];
//       return v != null && v.toString().isNotEmpty;
//     }).length;
//
//     final flowName = flowDef?['name'] as String?;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 4),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(8),
//         side: const BorderSide(color: AppColors.ctBorder),
//       ),
//       child: ExpansionTile(
//         tilePadding:
//             const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         childrenPadding:
//             const EdgeInsets.fromLTRB(16, 0, 16, 12),
//         shape: const RoundedRectangleBorder(),
//         collapsedShape: const RoundedRectangleBorder(),
//         title: Row(
//           children: [
//             Expanded(
//               child: flowDef != null
//                   ? Text(
//                       flowName ?? 'Sin nombre',
//                       overflow: TextOverflow.ellipsis,
//                       style: const TextStyle(
//                         fontFamily: 'Geist',
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                         color: AppColors.ctText,
//                       ),
//                     )
//                   : const Text(
//                       'Flow eliminado',
//                       style: TextStyle(
//                         fontFamily: 'Geist',
//                         fontSize: 13,
//                         fontStyle: FontStyle.italic,
//                         color: AppColors.ctText3,
//                       ),
//                     ),
//             ),
//             const SizedBox(width: 8),
//             _ExecStatusBadge(status: status),
//           ],
//         ),
//         subtitle: Padding(
//           padding: const EdgeInsets.only(top: 4, bottom: 4),
//           child: Row(
//             children: [
//               const Icon(Icons.person_outline,
//                   size: 12, color: AppColors.ctText3),
//               const SizedBox(width: 4),
//               Text(
//                 operator_?['name'] as String? ?? 'Sin operador',
//                 style: const TextStyle(
//                   fontFamily: 'Geist',
//                   fontSize: 11,
//                   color: AppColors.ctText3,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               const Icon(Icons.timer_outlined,
//                   size: 12, color: AppColors.ctText3),
//               const SizedBox(width: 4),
//               Text(
//                 _formatElapsed(elapsedSeconds),
//                 style: const TextStyle(
//                   fontFamily: 'Geist',
//                   fontSize: 11,
//                   color: AppColors.ctText3,
//                 ),
//               ),
//               if (flowDef != null) ...[
//                 const SizedBox(width: 12),
//                 Text(
//                   '$captured/${fieldsExpected.length} campos',
//                   style: const TextStyle(
//                     fontFamily: 'Geist',
//                     fontSize: 11,
//                     color: AppColors.ctTealDark,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//         children: [
//           if (flowDef != null && fieldsExpected.isNotEmpty)
//             ...List.generate(fieldsExpected.length, (i) {
//               final field = fieldsExpected[i];
//               final key = field['key'] as String? ?? '';
//               final label = field['label'] as String? ?? key;
//               final isRequired = field['required'] == true;
//               final value = fieldsCaptured[key];
//               final hasValue =
//                   value != null && value.toString().isNotEmpty;
//
//               return Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   if (i > 0) const Divider(height: 1),
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 6),
//                     child: Row(
//                       children: [
//                         Icon(
//                           hasValue
//                               ? Icons.check_circle
//                               : Icons.radio_button_unchecked,
//                           size: 14,
//                           color: hasValue
//                               ? AppColors.ctOk
//                               : AppColors.ctText3,
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             label,
//                             style: const TextStyle(
//                               fontFamily: 'Geist',
//                               fontSize: 12,
//                               color: AppColors.ctText,
//                             ),
//                           ),
//                         ),
//                         if (isRequired)
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 4, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: AppColors.ctWarnBg,
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: const Text(
//                               'req',
//                               style: TextStyle(
//                                 fontFamily: 'Geist',
//                                 fontSize: 9,
//                                 fontWeight: FontWeight.w600,
//                                 color: AppColors.ctWarnText,
//                               ),
//                             ),
//                           ),
//                         const SizedBox(width: 8),
//                         Text(
//                           hasValue ? value.toString() : '—',
//                           style: TextStyle(
//                             fontFamily: 'Geist',
//                             fontSize: 12,
//                             color: hasValue
//                                 ? AppColors.ctText
//                                 : AppColors.ctText3,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               );
//             }),
//           if (flowDef == null)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 const Text(
//                   'Definición de flujo no disponible',
//                   style: TextStyle(
//                     fontFamily: 'Geist',
//                     fontSize: 12,
//                     fontStyle: FontStyle.italic,
//                     color: AppColors.ctText3,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   jsonEncode(execution['fields_captured']),
//                   style: const TextStyle(
//                     fontSize: 10,
//                     fontFamily: 'monospace',
//                     color: AppColors.ctText2,
//                   ),
//                 ),
//               ],
//             ),
//           const SizedBox(height: 8),
//           SelectableText(
//             'ID: ${execution['execution_id']}',
//             style: const TextStyle(
//               fontSize: 10,
//               fontFamily: 'monospace',
//               color: AppColors.ctText3,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ── _ExecStatusBadge ──────────────────────────────────────────────────────────
//
// class _ExecStatusBadge extends StatelessWidget {
//   const _ExecStatusBadge({required this.status});
//
//   final String status;
//
//   @override
//   Widget build(BuildContext context) {
//     final Color bg;
//     final Color fg;
//
//     switch (status) {
//       case 'active':
//       case 'in_progress':
//         bg = AppColors.ctTealLight;
//         fg = AppColors.ctTealDark;
//       case 'completed':
//         bg = AppColors.ctOkBg;
//         fg = AppColors.ctOkText;
//       case 'abandoned':
//         bg = AppColors.ctSurface2;
//         fg = AppColors.ctText3;
//       case 'paused':
//         bg = AppColors.ctWarnBg;
//         fg = AppColors.ctWarnText;
//       default:
//         bg = AppColors.ctSurface2;
//         fg = AppColors.ctText2;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: bg,
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Text(
//         status,
//         style: TextStyle(
//           fontFamily: 'Geist',
//           fontSize: 10,
//           fontWeight: FontWeight.w600,
//           color: fg,
//         ),
//       ),
//     );
//   }
// }
