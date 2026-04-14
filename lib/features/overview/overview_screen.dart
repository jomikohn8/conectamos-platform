import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/operators_api.dart';
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

// ── Datos mock ────────────────────────────────────────────────────────────────

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

  // Colores según status
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

  // Flujos
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

  // Pie de tarjeta
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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de acciones fija — no entra en el scroll
        const _ActionBar(),

        // Contenido scrolleable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _KpiRow(),
                SizedBox(height: 18),
                Text(
                  'OPERADORES EN TURNO',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText3,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 12),
                _OperatorGrid(),
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
          // Título + subtítulo
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

          // Botón de fecha
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
          children: const [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: AppColors.ctText,
            ),
            SizedBox(width: 6),
            Text(
              '02 Abr 2026  ▾',
              style: TextStyle(
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
  const _KpiRow();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctTeal,
                label: 'OPERADORES ACTIVOS',
                value: '5 / 8',
                subtext: '3 sin turno hoy',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctOk,
                label: 'SESIONES ABIERTAS',
                value: '5',
                subtext: 'Flujos activos en curso',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctWarn,
                label: 'EVENTOS DEL DÍA',
                value: '143',
                subtext: 'Procesados por el sistema',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: KpiCard(
                topBorderColor: AppColors.ctDanger,
                label: 'INCIDENCIAS ABIERTAS',
                value: '2',
                subtext: 'Requieren atención',
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
  });

  final Color topBorderColor;
  final String label;
  final String value;
  final String subtext;

  @override
  Widget build(BuildContext context) {
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
          // Borde superior de color (3px)
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
          // Label
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
          // Valor
          Text(
            value,
            style: AppFonts.onest(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
          // Subtexto
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
  const _OperatorGrid();

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
    _load();
  }

  Future<void> _load() async {
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
      final raw = await OperatorsApi.listOperators();
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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/sessions/${Uri.encodeComponent(op.name)}'),
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
              // ── Header ──
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 13, 13, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    _OperatorAvatar(
                      initials: op.initials,
                      bg: op.avatarBg,
                      textColor: op.avatarTextColor,
                    ),
                    const SizedBox(width: 10),
                    // Nombre + teléfono
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
                    // Badge estado
                    StatusBadge(
                      label: op.statusLabel,
                      bg: op.statusBg,
                      textColor: op.statusTextColor,
                    ),
                  ],
                ),
              ),

              // ── Fila de flujos ──
              Padding(
                padding: const EdgeInsets.fromLTRB(13, 0, 13, 10),
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: op.flows
                      .map((f) => FlowBadge(data: f))
                      .toList(),
                ),
              ),

              const Spacer(),

              // ── Pie ──
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: AppColors.ctBorder),
                  ),
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
