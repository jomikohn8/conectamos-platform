import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class ExecutionMetadataSidebar extends StatelessWidget {
  const ExecutionMetadataSidebar({
    super.key,
    required this.exec,
    required this.flow,
  });

  final Map<String, dynamic> exec;
  final Map<String, dynamic> flow;

  static const _shortMonths = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _fmtDateLong(String? iso) {
    if (iso == null) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      return '${d.day.toString().padLeft(2, '0')} ${_shortMonths[d.month - 1]} · $h:$m';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = exec['status'] as String? ?? 'completed';
    final execId = exec['id'] as String? ?? '—';
    final startedAt = exec['started_at'] as String? ?? exec['startedAt'] as String?;
    final completedAt = exec['completed_at'] as String? ?? exec['completedAt'] as String?;
    final duration = exec['duration'] as String? ?? '—';
    final channel = exec['channel'] as String? ?? '—';
    final progress = (exec['progress'] as Map?)?.cast<String, dynamic>() ?? {};
    final filled = (progress['filled'] as num?)?.toInt() ?? 0;
    final total = (progress['total'] as num?)?.toInt() ?? 0;

    final operator_ = (exec['operator'] as Map?)?.cast<String, dynamic>() ?? {};
    final opName = operator_['name'] as String? ?? 'Sin operador';
    final opRole = operator_['role'] as String? ?? '';
    final opAvatar = operator_['avatar'] as String?;

    final flowName = flow['name'] as String? ?? '—';
    final flowSlug = flow['slug'] as String? ?? exec['flow_slug'] as String? ?? exec['flowSlug'] as String? ?? '';
    final flowDesc = flow['description'] as String? ?? '';
    final flowType = flow['type'] as String? ?? 'conversacional';
    final worker = (flow['worker'] as Map?)?.cast<String, dynamic>() ?? {};
    final workerName = worker['name'] as String? ?? '—';
    final workerRole = worker['role'] as String? ?? '';
    final behavior = (flow['behavior'] as Map?)?.cast<String, dynamic>() ?? {};
    final onComplete = (behavior['onComplete'] as List?)?.cast<String>() ?? [];
    final emits = (behavior['emits'] as List?)?.cast<String>() ?? [];

    final inheritedValues = (exec['inherited_values'] as Map?)?.cast<String, dynamic>() ??
        (exec['inheritedValues'] as Map?)?.cast<String, dynamic>() ?? {};

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detalle de ejecución ──────────────────────────────────────────
          _SideCard(
            title: 'Detalle de ejecución',
            child: Column(
              children: [
                _KV(
                  label: 'Execution ID',
                  value: Text(execId,
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: AppColors.ctNavy,
                          letterSpacing: -0.005)),
                ),
                _KV(label: 'Iniciada', value: Text(_fmtDateLong(startedAt),
                    style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy))),
                _KV(
                  label: status == 'in-progress' ? 'Tiempo activo' : 'Finalizada',
                  value: Text(
                      status == 'in-progress' ? duration : _fmtDateLong(completedAt),
                      style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy)),
                ),
                _KV(
                  label: 'Duración total',
                  value: Text(duration,
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 12,
                          color: AppColors.ctNavy,
                          fontFeatures: [FontFeature.tabularFigures()])),
                ),
                _KV(
                  label: 'Canal',
                  value: _ChannelLabel(channel: channel),
                ),
                _KV(
                  label: 'Progreso',
                  value: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$filled / $total',
                          style: AppFonts.geist(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ctNavy)),
                      const SizedBox(width: 6),
                      Text('campos',
                          style: AppFonts.geist(
                              fontSize: 11, color: const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Operador ──────────────────────────────────────────────────────
          _SideCard(
            title: 'Operador',
            child: Row(
              children: [
                _AvatarLarge(src: opAvatar, name: opName, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(opName,
                          style: AppFonts.geist(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ctNavy)),
                      if (opRole.isNotEmpty)
                        Text(opRole,
                            style: AppFonts.geist(
                                fontSize: 12, color: const Color(0xFF475569))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Flujo definido ────────────────────────────────────────────────
          _SideCard(
            title: 'Flujo definido',
            action: TextButton.icon(
              onPressed: () {
                if (flowSlug.isNotEmpty) context.go('/flows/$flowSlug');
              },
              icon: const Icon(Icons.arrow_outward_rounded, size: 12),
              label: const Text('Editor'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ctTeal,
                textStyle:
                    AppFonts.geist(fontSize: 12, fontWeight: FontWeight.w600),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _FlowIconTile(flowType: flowType),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(flowName,
                              style: AppFonts.geist(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ctNavy)),
                          Text('/$flowSlug',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 11,
                                color: Color(0xFF475569),
                              )),
                        ],
                      ),
                    ),
                  ],
                ),
                if (flowDesc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(flowDesc,
                      style: AppFonts.geist(
                          fontSize: 12, color: const Color(0xFF475569), height: 1.55)),
                ],
                const SizedBox(height: 10),
                // Worker sub-card
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    border: Border.all(color: AppColors.ctBorder),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.ctNavy,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.auto_awesome_rounded,
                            size: 12, color: AppColors.ctTeal),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(workerName,
                                style: AppFonts.geist(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.ctNavy)),
                            if (workerRole.isNotEmpty)
                              Text(workerRole,
                                  style: AppFonts.geist(
                                      fontSize: 10, color: const Color(0xFF475569))),
                          ],
                        ),
                      ),
                      _Badge(label: 'IA'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Heredados ─────────────────────────────────────────────────────
          if (inheritedValues.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SideCard(
              title: 'Heredados del flujo previo',
              titleIcon: const Icon(Icons.arrow_back_rounded,
                  size: 12, color: Color(0xFF4338CA)),
              child: Column(
                children: inheritedValues.entries.map((e) {
                  final label = e.key.replaceAll('_', ' ');
                  return _KV(
                    label: label,
                    value: Text(e.value.toString(),
                        style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy)),
                  );
                }).toList(),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // ── Comportamiento ────────────────────────────────────────────────
          _SideCard(
            title: 'Comportamiento',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AL COMPLETAR',
                    style: AppFonts.geist(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.06,
                      color: const Color(0xFF94A3B8),
                    )),
                const SizedBox(height: 6),
                if (onComplete.isEmpty)
                  Text('Sin acciones automáticas',
                      style:
                          AppFonts.geist(fontSize: 12, color: const Color(0xFF94A3B8)))
                else
                  Column(
                    children: onComplete.map((b) => Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.ctSurface2,
                              border: Border.all(color: AppColors.ctBorder),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.account_tree_rounded,
                                    size: 12, color: AppColors.ctTeal),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(b,
                                      style: const TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 12,
                                          color: AppColors.ctNavy)),
                                ),
                              ],
                            ),
                          ),
                        )).toList(),
                  ),
                if (emits.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('EVENTOS EMITIDOS',
                      style: AppFonts.geist(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.06,
                        color: const Color(0xFF94A3B8),
                      )),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: emits
                        .map((e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(e,
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.ctNavy,
                                  )),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SideCard extends StatelessWidget {
  const _SideCard({required this.title, required this.child, this.action, this.titleIcon});
  final String title;
  final Widget child;
  final Widget? action;
  final Widget? titleIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A0F172A), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                if (titleIcon != null) ...[titleIcon!, const SizedBox(width: 6)],
                Expanded(
                  child: Text(title,
                      style: AppFonts.onest(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctNavy)),
                ),
                ?action,
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.ctBorder),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppFonts.geist(fontSize: 12, color: const Color(0xFF475569))),
          ),
          const SizedBox(width: 8),
          Expanded(child: value),
        ],
      ),
    );
  }
}

class _ChannelLabel extends StatelessWidget {
  const _ChannelLabel({required this.channel});
  final String channel;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    if (channel.contains('WhatsApp')) {
      icon = Icons.chat_rounded;
      color = const Color(0xFF25D366);
    } else if (channel.contains('API')) {
      icon = Icons.code_rounded;
      color = AppColors.ctInfo;
    } else {
      icon = Icons.dashboard_outlined;
      color = const Color(0xFF475569);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(channel,
            style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy)),
      ],
    );
  }
}

class _FlowIconTile extends StatelessWidget {
  const _FlowIconTile({required this.flowType});
  final String flowType;

  @override
  Widget build(BuildContext context) {
    final icon = switch (flowType) {
      'api'       => Icons.code_rounded,
      'dashboard' => Icons.dashboard_outlined,
      _           => Icons.chat_bubble_outline_rounded,
    };
    return Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.ctTeal, Color(0xFF15A99A)],
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
              color: Color(0x260B132B), offset: Offset(0, 1), blurRadius: 2),
        ],
      ),
      child: Icon(icon, size: 16, color: AppColors.ctNavy),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ctTealLight,
        border: Border.all(color: const Color(0xFF99F6E4)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(label,
          style: AppFonts.geist(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F766E))),
    );
  }
}

class _AvatarLarge extends StatelessWidget {
  const _AvatarLarge({required this.name, required this.size, this.src});
  final String? src;
  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    return ClipOval(
      child: SizedBox(
        width: size, height: size,
        child: src != null
            ? Image.network(src!, fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => _Initials(initials: initials, size: size))
            : _Initials(initials: initials, size: size),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({required this.initials, required this.size});
  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE0F2FE),
      child: Center(
        child: Text(initials,
            style: AppFonts.geist(
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
                color: AppColors.ctInfoText)),
      ),
    );
  }
}
