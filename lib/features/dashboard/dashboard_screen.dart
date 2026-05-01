import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

/// true = el dashboard ya tiene widgets configurados
final dashboardConfiguredProvider = StateProvider<bool>((ref) => false);

/// Texto del prompt que el usuario escribió al configurar
final dashboardPromptProvider = StateProvider<String>((ref) => '');

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
    final configured = ref.watch(dashboardConfiguredProvider);

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
                  'Configura las métricas que quieres ver',
                  style: AppTextStyles.topbarSubtitle,
                ),
              ],
            ),
          ),
          if (configured)
            _GhostButton(
              label: 'Restablecer',
              icon: Icons.restart_alt_rounded,
              onTap: () {
                ref.read(dashboardConfiguredProvider.notifier).state = false;
                ref.read(dashboardPromptProvider.notifier).state = '';
              },
            ),
        ],
      ),
    );
  }
}

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
    final configured = ref.watch(dashboardConfiguredProvider);
    return configured ? const _ConfiguredView() : const _EmptyView();
  }
}

// ── Estado vacío ──────────────────────────────────────────────────────────────

class _EmptyView extends ConsumerStatefulWidget {
  const _EmptyView();

  @override
  ConsumerState<_EmptyView> createState() => _EmptyViewState();
}

class _EmptyViewState extends ConsumerState<_EmptyView> {
  final _ctrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _loading = true);
    // Simula latencia de generación
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    ref.read(dashboardPromptProvider.notifier).state = text;
    ref.read(dashboardConfiguredProvider.notifier).state = true;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícono
            const Icon(
              Icons.dashboard_customize_outlined,
              size: 48,
              color: AppColors.ctBorder2,
            ),
            const SizedBox(height: 16),

            // Título
            const Text(
              'Tu dashboard está vacío',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.ctText,
              ),
            ),
            const SizedBox(height: 6),

            // Subtítulo
            const SizedBox(
              width: 340,
              child: Text(
                'Dinos qué métricas te importan y generamos tu vista en segundos.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Caja de prompt
            _PromptBox(ctrl: _ctrl, loading: _loading, onSubmit: _submit),
            const SizedBox(height: 20),

            // Sugerencias rápidas
            const _QuickSuggestions(),
          ],
        ),
      ),
    );
  }
}

// ── Caja de prompt ────────────────────────────────────────────────────────────

class _PromptBox extends StatefulWidget {
  const _PromptBox({
    required this.ctrl,
    required this.loading,
    required this.onSubmit,
  });
  final TextEditingController ctrl;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  State<_PromptBox> createState() => _PromptBoxState();
}

class _PromptBoxState extends State<_PromptBox> {
  bool _hoverSend = false;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.ctSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.ctBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            const Text(
              '¿Qué quieres monitorear?',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText,
              ),
            ),
            const SizedBox(height: 10),

            // Campo de texto
            TextField(
              controller: widget.ctrl,
              maxLines: 3,
              minLines: 3,
              enabled: !widget.loading,
              onSubmitted: (_) => widget.onSubmit(),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText,
                height: 1.5,
              ),
              decoration: InputDecoration(
                hintText:
                    'Ej: "Quiero ver operadores activos, sesiones abiertas y las últimas alertas del día"',
                hintStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText3,
                  height: 1.5,
                ),
                filled: true,
                fillColor: AppColors.ctSurface2,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.ctBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.ctBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.ctTeal, width: 1.5),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.ctBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Pie: hint + botón
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: AppColors.ctText3,
                ),
                const SizedBox(width: 5),
                const Expanded(
                  child: Text(
                    'Generación automática con IA · solo datos de tu operación',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      color: AppColors.ctText3,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Botón generar
                MouseRegion(
                  onEnter: (_) => setState(() => _hoverSend = true),
                  onExit: (_) => setState(() => _hoverSend = false),
                  cursor: widget.loading
                      ? SystemMouseCursors.wait
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.loading ? null : widget.onSubmit,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.loading
                            ? AppColors.ctTeal.withValues(alpha: 0.6)
                            : _hoverSend
                                ? AppColors.ctTealDark
                                : AppColors.ctTeal,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.loading)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    AppColors.ctNavy),
                              ),
                            )
                          else
                            const Icon(
                              Icons.auto_awesome_rounded,
                              size: 13,
                              color: AppColors.ctNavy,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            widget.loading ? 'Generando…' : 'Generar',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ctNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sugerencias rápidas ───────────────────────────────────────────────────────

class _QuickSuggestions extends StatelessWidget {
  const _QuickSuggestions();

  static const _suggestions = [
    'Operadores activos y sus flujos',
    'Alertas e incidencias del día',
    'Sesiones abiertas y cerradas',
    'Eventos procesados por hora',
  ];

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SUGERENCIAS',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText3,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _suggestions.map((s) => _SuggestionChip(label: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatefulWidget {
  const _SuggestionChip({required this.label});
  final String label;

  @override
  State<_SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<_SuggestionChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding:
              const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color:
                _hovered ? AppColors.ctSurface2 : AppColors.ctSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered ? AppColors.ctBorder2 : AppColors.ctBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 12,
                color: AppColors.ctText3,
              ),
              const SizedBox(width: 4),
              Text(
                widget.label,
                style: AppTextStyles.navItem,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Estado configurado ────────────────────────────────────────────────────────

class _ConfiguredView extends ConsumerWidget {
  const _ConfiguredView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prompt = ref.watch(dashboardPromptProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner: qué se generó
          _PromptBanner(prompt: prompt),
          const SizedBox(height: 20),

          // Fila de KPIs generados
          const _DashKpiRow(),
          const SizedBox(height: 16),

          // Segunda fila: tabla de alertas + panel de sesiones
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 3, child: _AlertasCard()),
                    SizedBox(width: 14),
                    Expanded(flex: 2, child: _SesionesCard()),
                  ],
                );
              }
              return const Column(
                children: [
                  _AlertasCard(),
                  SizedBox(height: 14),
                  _SesionesCard(),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Fila inferior: eventos por hora (sparkline mock) + flujos activos
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(flex: 2, child: _EventosCard()),
                    SizedBox(width: 14),
                    Expanded(flex: 3, child: _FlujosCard()),
                  ],
                );
              }
              return const Column(
                children: [
                  _EventosCard(),
                  SizedBox(height: 14),
                  _FlujosCard(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Banner del prompt ─────────────────────────────────────────────────────────

class _PromptBanner extends StatelessWidget {
  const _PromptBanner({required this.prompt});
  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ctTealLight,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(
          color: AppColors.ctTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 14,
            color: AppColors.ctTealDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctTealDark,
                ),
                children: [
                  const TextSpan(
                    text: 'Dashboard generado para: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: prompt),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── KPI row del dashboard configurado ────────────────────────────────────────

class _DashKpiRow extends StatelessWidget {
  const _DashKpiRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _DashKpiCard(
            color: AppColors.ctTeal,
            icon: Icons.people_outline_rounded,
            label: 'OPERADORES ACTIVOS',
            value: '5 / 8',
            sub: '3 sin turno hoy',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _DashKpiCard(
            color: AppColors.ctOk,
            icon: Icons.check_circle_outline_rounded,
            label: 'SESIONES ABIERTAS',
            value: '5',
            sub: 'Flujos en curso',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _DashKpiCard(
            color: AppColors.ctWarn,
            icon: Icons.bolt_outlined,
            label: 'EVENTOS HOY',
            value: '143',
            sub: 'Procesados por sistema',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _DashKpiCard(
            color: AppColors.ctDanger,
            icon: Icons.warning_amber_rounded,
            label: 'ALERTAS ABIERTAS',
            value: '2',
            sub: 'Requieren atención',
          ),
        ),
      ],
    );
  }
}

class _DashKpiCard extends StatelessWidget {
  const _DashKpiCard({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
  });
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String sub;

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
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText2,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
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

// ── Tarjeta: Alertas ──────────────────────────────────────────────────────────

class _AlertaItem {
  const _AlertaItem({
    required this.operator,
    required this.desc,
    required this.time,
    required this.severityBg,
    required this.severityText,
    required this.severityLabel,
  });
  final String operator;
  final String desc;
  final String time;
  final Color severityBg;
  final Color severityText;
  final String severityLabel;
}

const _kAlertas = [
  _AlertaItem(
    operator: 'Miguel Herrera',
    desc: 'Sin actualización · 32 min sin reporte',
    time: '09:18',
    severityBg: AppColors.ctRedBg,
    severityText: AppColors.ctRedText,
    severityLabel: 'Alta',
  ),
  _AlertaItem(
    operator: 'Jorge López',
    desc: 'En espera · flujo pausado sin confirmación',
    time: '09:33',
    severityBg: AppColors.ctWarnBg,
    severityText: AppColors.ctWarnText,
    severityLabel: 'Media',
  ),
];

class _AlertasCard extends StatelessWidget {
  const _AlertasCard();

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      title: 'Alertas e incidencias',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.ctRedBg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '2 activas',
          style: AppTextStyles.badge.copyWith(color: AppColors.ctRedText),
        ),
      ),
      child: Column(
        children: _kAlertas
            .map((a) => _AlertaRow(item: a))
            .toList(),
      ),
    );
  }
}

class _AlertaRow extends StatefulWidget {
  const _AlertaRow({required this.item});
  final _AlertaItem item;

  @override
  State<_AlertaRow> createState() => _AlertaRowState();
}

class _AlertaRowState extends State<_AlertaRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.item;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.ctSurface2 : AppColors.ctSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: a.severityBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                a.severityLabel,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: a.severityText,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.operator,
                    style: AppTextStyles.tenantName,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    a.desc,
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              a.time,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 11,
                color: AppColors.ctText3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta: Sesiones ─────────────────────────────────────────────────────────

class _SesionItem {
  const _SesionItem({
    required this.name,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.status,
    required this.statusBg,
    required this.statusTextColor,
    required this.since,
  });
  final String name;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final String status;
  final Color statusBg;
  final Color statusTextColor;
  final String since;
}

const _kSesiones = [
  _SesionItem(
    name: 'Roberto Medina',
    initials: 'RM',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    status: 'En curso',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    since: '07:03',
  ),
  _SesionItem(
    name: 'Andrés Pérez',
    initials: 'AP',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    status: 'En curso',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    since: '07:18',
  ),
  _SesionItem(
    name: 'Luis Castro',
    initials: 'LC',
    avatarBg: AppColors.ctTealLight,
    avatarTextColor: AppColors.ctTealDark,
    status: 'En curso',
    statusBg: AppColors.ctOkBg,
    statusTextColor: AppColors.ctOkText,
    since: '07:41',
  ),
  _SesionItem(
    name: 'Jorge López',
    initials: 'JL',
    avatarBg: AppColors.ctWarnBg,
    avatarTextColor: AppColors.ctWarnText,
    status: 'En espera',
    statusBg: AppColors.ctWarnBg,
    statusTextColor: AppColors.ctWarnText,
    since: '08:02',
  ),
  _SesionItem(
    name: 'Miguel Herrera',
    initials: 'MH',
    avatarBg: AppColors.ctRedBg,
    avatarTextColor: AppColors.ctRedText,
    status: 'Incidencia',
    statusBg: AppColors.ctRedBg,
    statusTextColor: AppColors.ctRedText,
    since: '08:15',
  ),
];

class _SesionesCard extends StatelessWidget {
  const _SesionesCard();

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      title: 'Sesiones abiertas',
      trailing: Text(
        '${_kSesiones.length} activas',
        style: AppTextStyles.bodySmall,
      ),
      child: Column(
        children: _kSesiones.map((s) => _SesionRow(item: s)).toList(),
      ),
    );
  }
}

class _SesionRow extends StatelessWidget {
  const _SesionRow({required this.item});
  final _SesionItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.initials,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: item.avatarTextColor,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ctText,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'desde ${item.since}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: item.statusBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: item.statusTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tarjeta: Eventos por hora (sparkline mock) ────────────────────────────────

const _kEventosBars = [12, 8, 21, 34, 28, 19, 41, 37, 29, 22, 15, 11];
const _kEventosHoras = [
  '07',
  '08',
  '09',
  '10',
  '11',
  '12',
  '13',
  '14',
  '15',
  '16',
  '17',
  '18'
];

class _EventosCard extends StatelessWidget {
  const _EventosCard();

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      title: 'Eventos por hora',
      trailing: Text(
        '143 hoy',
        style: AppTextStyles.bodySmall,
      ),
      child: _BarChart(
        values: _kEventosBars,
        labels: _kEventosHoras,
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels});
  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxVal = values.reduce((a, b) => a > b ? a : b);
    const barH = 80.0;

    return Column(
      children: [
        SizedBox(
          height: barH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(values.length, (i) {
              final frac = values[i] / maxVal;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _Bar(fraction: frac, value: values[i]),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: List.generate(labels.length, (i) {
            return Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 9,
                  color: AppColors.ctText3,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({required this.fraction, required this.value});
  final double fraction;
  final int value;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: '${widget.value} eventos',
        waitDuration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 80 * widget.fraction,
              decoration: BoxDecoration(
                color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta: Flujos activos ───────────────────────────────────────────────────

class _FlujoStat {
  const _FlujoStat({
    required this.name,
    required this.active,
    required this.completed,
    required this.color,
  });
  final String name;
  final int active;
  final int completed;
  final Color color;
}

const _kFlujos = [
  _FlujoStat(
    name: 'Flujo 1 · Turno',
    active: 5,
    completed: 0,
    color: AppColors.ctOk,
  ),
  _FlujoStat(
    name: 'Flujo 2 · Registros',
    active: 3,
    completed: 12,
    color: AppColors.ctTeal,
  ),
  _FlujoStat(
    name: 'Flujo 3 · Incidencias',
    active: 1,
    completed: 8,
    color: AppColors.ctWarn,
  ),
];

class _FlujosCard extends StatelessWidget {
  const _FlujosCard();

  @override
  Widget build(BuildContext context) {
    return _DashCard(
      title: 'Flujos activos',
      child: Column(
        children: _kFlujos.map((f) => _FlujoRow(item: f)).toList(),
      ),
    );
  }
}

class _FlujoRow extends StatelessWidget {
  const _FlujoRow({required this.item});
  final _FlujoStat item;

  @override
  Widget build(BuildContext context) {
    final total =
        item.active + item.completed == 0 ? 1 : item.active + item.completed;
    final fraction = item.active / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ctText,
                  ),
                ),
              ),
              Text(
                '${item.active} activos',
                style: AppTextStyles.badge.copyWith(color: item.color),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${item.completed} completados',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: AppColors.ctText3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Barra de progreso
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 5,
              backgroundColor: AppColors.ctSurface2,
              valueColor: AlwaysStoppedAnimation<Color>(item.color),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget genérico de card ───────────────────────────────────────────────────

class _DashCard extends StatelessWidget {
  const _DashCard({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
