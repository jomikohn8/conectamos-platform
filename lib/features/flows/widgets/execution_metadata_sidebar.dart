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
    final execId = exec['id'] as String? ?? '—';
    final startedAt = exec['created_at'] as String?;
    final completedAt = exec['completed_at'] as String?;
    // Compute progress: match each snapshot field to its field_value by key
    final rawFvList = exec['field_values'] as List? ?? [];
    final fvMap = <String, Map>{};
    for (final fv in rawFvList.whereType<Map>()) {
      final k = fv['field_key'];
      if (k is String && k.isNotEmpty) fvMap[k] = fv;
    }
    final snapshotFields = (flow['fields'] as List?)?.whereType<Map>().toList() ?? [];
    final total = snapshotFields.length;
    int filled = 0;
    for (final field in snapshotFields) {
      final key = field['key'];
      if (key is! String) continue;
      final fv = fvMap[key];
      if (fv != null &&
          (fv['value_text'] != null ||
           fv['value_numeric'] != null ||
           fv['value_media_url'] != null ||
           fv['value_jsonb'] != null)) {
        filled++;
      }
    }

    // Channel (nested Map or fallback to actor_type)
    final channelRaw = exec['channel'];
    final Map<String, dynamic>? channelMap = channelRaw is Map
        ? Map<String, dynamic>.from(channelRaw)
        : null;
    final channelType = channelMap?['channel_type'] as String?;
    final channelDisplayName = channelMap?['display_name'] as String?;
    // Fallback: infer from actor_type when channel is null
    final actorType = exec['actor_type'] as String?;
    final inferredChannelType = channelType ??
        switch (actorType) {
          'operator'    => 'whatsapp',
          'tenant_user' => 'dashboard',
          'system'      => 'api',
          _             => null,
        };
    final resolvedDisplayName = channelDisplayName ??
        switch (inferredChannelType) {
          'whatsapp'  => 'WhatsApp',
          'telegram'  => 'Telegram',
          'api'       => 'API',
          'dashboard' => 'Dashboard',
          _           => null,
        };

    final operatorRaw = exec['operator'];
    final Map<String, dynamic>? operator_ = operatorRaw is Map
        ? Map<String, dynamic>.from(operatorRaw)
        : null;
    final opName = operator_?['name'] as String? ?? 'Sin operador';
    final opAvatar = operator_?['profile_picture_url'] as String?;

    final flowName = flow['name'] as String? ?? '—';
    final flowSlug = flow['slug'] as String? ?? '';
    final flowDesc = flow['description'] as String? ?? '';
    final triggerSources = flow['trigger_sources'] as List?;
    final flowType = triggerSources?.firstOrNull?.toString() ?? 'conversacional';

    // Worker now at exec['worker'] (not flow['worker'])
    final worker = (exec['worker'] as Map?)?.cast<String, dynamic>();
    final workerName = worker?['name'] as String? ?? '—';
    final workerRole = worker?['role'] as String? ?? '';

    // on_complete from snapshot
    final rawOnComplete = flow['on_complete'];
    final onComplete = rawOnComplete is List
        ? rawOnComplete.whereType<String>().toList()
        : <String>[];

    final inheritedValues = <String, dynamic>{};

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Detalle de ejecución ──────────────────────────────────────────
          _SideCard(
            title: 'Detalle de ejecución',
            child: Column(
              children: _withDividers([
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
                  label: 'Finalizada',
                  value: Text(_fmtDateLong(completedAt),
                      style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy)),
                ),
                _KV(
                  label: 'Canal',
                  value: inferredChannelType != null
                      ? _ChannelLabel(
                          channelType: inferredChannelType,
                          displayName: resolvedDisplayName ?? '—')
                      : Text('—',
                          style: AppFonts.geist(
                              fontSize: 12, color: AppColors.ctNavy)),
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
              ]),
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
                if (worker != null) ...[
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
                                        fontSize: 10,
                                        color: const Color(0xFF475569))),
                            ],
                          ),
                        ),
                        _Badge(label: 'IA'),
                      ],
                    ),
                  ),
                ],
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

List<Widget> _withDividers(List<Widget> items) {
  const divider = Divider(color: Color(0xFFE5E7EB), thickness: 1, height: 1);
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) result.add(divider);
  }
  return result;
}

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
  const _ChannelLabel({required this.channelType, required this.displayName});
  final String channelType;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (channelType) {
      case 'whatsapp':
        icon = Icons.chat_rounded;
        color = const Color(0xFF25D366);
      case 'telegram':
        icon = Icons.send_rounded;
        color = const Color(0xFF229ED9);
      case 'api':
        icon = Icons.code_rounded;
        color = AppColors.ctInfo;
      default:
        icon = Icons.dashboard_outlined;
        color = const Color(0xFF475569);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(displayName,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.geist(fontSize: 12, color: AppColors.ctNavy)),
        ),
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
