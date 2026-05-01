import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/flows_api.dart';
import '../../core/providers/permissions_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';
import 'widgets/execution_header_block.dart';
import 'widgets/execution_metadata_sidebar.dart';
import 'widgets/field_card.dart';
import 'widgets/lineage_breadcrumb.dart';
import 'widgets/messages_thread.dart';

class ExecutionDetailScreen extends ConsumerStatefulWidget {
  const ExecutionDetailScreen({super.key, required this.executionId});
  final String executionId;

  @override
  ConsumerState<ExecutionDetailScreen> createState() =>
      _ExecutionDetailScreenState();
}

class _ExecutionDetailScreenState
    extends ConsumerState<ExecutionDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _exec;
  Map<String, dynamic>? _flow;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final raw = await FlowsApi.getExecution(
          tenantId: tenantId, executionId: widget.executionId);
      final snapshot =
          (raw['flow_definition_snapshot'] as Map?)?.cast<String, dynamic>() ??
              {};
      setState(() {
        _exec = raw;
        _flow = snapshot;
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
    // Permission guard
    final perms = ref.watch(userPermissionsProvider);
    if (perms.valueOrNull != null &&
        !perms.valueOrNull!.contains('flows.view')) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go('/overview'));
      return const SizedBox.shrink();
    }

    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.ctBg,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.ctTeal),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!,
                  style: AppFonts.geist(
                      fontSize: 14, color: AppColors.ctDanger)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _load,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final exec = _exec!;
    final flow = _flow!;

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      body: SelectionArea(child: Column(
        children: [
          ExecutionHeaderBlock(exec: exec, flow: flow),
          Expanded(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LineageBreadcrumb(exec: exec),
                        LayoutBuilder(
                          builder: (ctx, constraints) {
                            final wide = constraints.maxWidth >= 900;
                            final content = _MainContent(exec: exec, flow: flow);
                            final sidebar =
                                ExecutionMetadataSidebar(exec: exec, flow: flow);

                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: content),
                                  const SizedBox(width: 22),
                                  sidebar,
                                ],
                              );
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                content,
                                const SizedBox(height: 22),
                                sidebar,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      )),
    );
  }
}

// ── Main content (fields + messages) ─────────────────────────────────────────

class _MainContent extends StatelessWidget {
  const _MainContent({required this.exec, required this.flow});
  final Map<String, dynamic> exec;
  final Map<String, dynamic> flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldsBlock(exec: exec, flow: flow),
        const SizedBox(height: 22),
        _MessagesBlock(exec: exec),
      ],
    );
  }
}

// ── Fields Block ──────────────────────────────────────────────────────────────

class _FieldsBlock extends StatefulWidget {
  const _FieldsBlock({required this.exec, required this.flow});
  final Map<String, dynamic> exec;
  final Map<String, dynamic> flow;

  @override
  State<_FieldsBlock> createState() => _FieldsBlockState();
}

class _FieldsBlockState extends State<_FieldsBlock> {
  final Set<String> _hiddenTypes = {};

  static const List<(String, IconData, String)> _typeOrder = [
    ('text',     Icons.notes_rounded,          'Texto'),
    ('number',   Icons.tag_rounded,            'Número'),
    ('date',     Icons.calendar_month_rounded, 'Fecha'),
    ('yesno',    Icons.toggle_on_rounded,      'Sí/No'),
    ('select',   Icons.checklist_rounded,      'Selección'),
    ('media',    Icons.camera_alt_rounded,     'Foto'),
    ('location', Icons.location_on_rounded,    'Ubicación'),
  ];

  static String _normalizeType(String t) => t == 'photo' ? 'media' : t;

  static bool _fvHasValue(Map<String, dynamic> fv) =>
      fv['value_text'] != null ||
      fv['value_numeric'] != null ||
      fv['value_media_url'] != null ||
      fv['value_jsonb'] != null;

  static dynamic _resolveValue(String type, Map<String, dynamic> fv) {
    return switch (type) {
      'number'             => fv['value_numeric'],
      'media' || 'photo'   => _resolveMedia(fv),
      'location'           => _resolveLocation(fv),
      _                    => fv['value_text'],
    };
  }

  static List<String> _resolveMedia(Map<String, dynamic> fv) {
    final jsonb = fv['value_jsonb'];
    if (jsonb is Map) {
      final url = jsonb['url'] as String?;
      if (url != null) return [url];
    }
    final mediaUrl = fv['value_media_url'] as String?;
    if (mediaUrl != null) return [mediaUrl];
    return [];
  }

  static Map<String, dynamic>? _resolveLocation(Map<String, dynamic> fv) {
    final jsonb = fv['value_jsonb'];
    if (jsonb is! Map) return null;
    final result = Map<String, dynamic>.from(jsonb.cast<String, dynamic>());
    final address = fv['value_text'] as String?;
    if (address != null) result['address'] = address;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final rawFields = widget.flow['fields'] as List? ?? [];
    final fields = rawFields
        .whereType<Map>()
        .map((f) => f.cast<String, dynamic>())
        .toList();

    // Build field_values lookup keyed by field_key
    final rawFvList = widget.exec['field_values'] as List? ?? [];
    final fvMap = <String, Map>{};
    for (final item in rawFvList.whereType<Map>()) {
      final k = item['field_key'];
      if (k is String && k.isNotEmpty) fvMap[k] = item;
    }

    // Types present in this flow (normalized)
    final presentTypes = fields
        .map((f) => _normalizeType(f['type'] as String? ?? 'text'))
        .toSet();

    // Progress
    final total = fields.length;
    final filled = fields.where((f) {
      final key = f['key'];
      if (key is! String) return false;
      final fv = fvMap[key];
      return fv != null && _fvHasValue(fv.cast<String, dynamic>());
    }).length;

    // Resolve values and pending list
    final values = <String, dynamic>{};
    final pending = <String>[];
    for (final field in fields) {
      final key = field['key'] as String? ?? '';
      final fvRaw = fvMap[key];
      final fv = fvRaw?.cast<String, dynamic>();
      if (fv == null || !_fvHasValue(fv)) {
        pending.add(key);
      } else {
        values[key] = _resolveValue(field['type'] as String? ?? 'text', fv);
      }
    }

    // Visible fields after type filter
    final visibleFields = fields
        .where((f) =>
            !_hiddenTypes.contains(_normalizeType(f['type'] as String? ?? 'text')))
        .toList();

    // Legacy field_values not in snapshot
    final knownKeys = fields.map((f) => f['key'] as String? ?? '').toSet();
    final legacyKeys = fvMap.keys.where((k) => !knownKeys.contains(k)).toList();
    final legacyValues = <String, dynamic>{
      for (final k in legacyKeys)
        k: fvMap[k]!['value_text'] ?? fvMap[k]!['value_numeric'] ?? '—',
    };

    if (fields.isEmpty && fvMap.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspaces_outline,
              size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text('Este flujo no tiene campos definidos',
              style: AppFonts.geist(
                      fontSize: 14, color: const Color(0xFF94A3B8))
                  .copyWith(fontStyle: FontStyle.italic)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Title + type filter icons ───────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Campos capturados',
                    style: AppFonts.onest(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctNavy,
                      letterSpacing: -0.02,
                    )),
                const SizedBox(height: 2),
                Text('$filled de $total campos con valor',
                    style: AppFonts.geist(
                        fontSize: 12, color: const Color(0xFF6B7280))),
              ],
            ),
            Row(
              children: [
                for (final (type, icon, label) in _typeOrder)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: _TypeFilterIcon(
                      icon: icon,
                      label: label,
                      exists: presentTypes.contains(type),
                      active: !_hiddenTypes.contains(type),
                      onToggle: () => setState(() {
                        if (_hiddenTypes.contains(type)) {
                          _hiddenTypes.remove(type);
                        } else {
                          _hiddenTypes.add(type);
                        }
                      }),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final totalWidth = constraints.maxWidth;
            const gap = 14.0;
            return _WrapGrid(
              fields: visibleFields,
              values: values,
              pending: pending,
              totalWidth: totalWidth,
              gap: gap,
            );
          },
        ),
        if (legacyKeys.isNotEmpty) ...[
          const SizedBox(height: 22),
          _LegacyFieldsCard(slugs: legacyKeys, values: legacyValues),
        ],
      ],
    );
  }
}

// ── Type Filter Icon ───────────────────────────────────────────────────────────

class _TypeFilterIcon extends StatelessWidget {
  const _TypeFilterIcon({
    required this.icon,
    required this.label,
    required this.exists,
    required this.active,
    required this.onToggle,
  });

  final IconData icon;
  final String label;
  final bool exists;
  final bool active;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color iconColor;

    if (!exists) {
      bg = const Color(0xFFF1F3F5);
      border = const Color(0xFFE5E7EB);
      iconColor = const Color(0xFFCBD5E1);
    } else if (active) {
      bg = const Color(0xFFCCFBF1);
      border = const Color(0xFF59E0CC);
      iconColor = const Color(0xFF0F766E);
    } else {
      bg = Colors.white;
      border = const Color(0xFFE5E7EB);
      iconColor = const Color(0xFF94A3B8);
    }

    final tile = Tooltip(
      message: label,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 13, color: iconColor),
      ),
    );

    if (!exists) {
      return MouseRegion(cursor: SystemMouseCursors.forbidden, child: tile);
    }
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onToggle, child: tile),
    );
  }
}

class _WrapGrid extends StatelessWidget {
  const _WrapGrid({
    required this.fields,
    required this.values,
    required this.pending,
    required this.totalWidth,
    required this.gap,
  });

  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> values;
  final List<String> pending;
  final double totalWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final halfWidth = (totalWidth - gap) / 2;

    final List<Widget> items = fields.map((field) {
      final key = field['key'] as String? ?? '';
      final value = values[key];
      final isPending = pending.contains(key);
      final card = FieldCard(
        field: field,
        value: value,
        isPending: isPending,
        isInherited: false,
      );
      final isWide = card.isWide;
      return SizedBox(
        width: isWide ? totalWidth : halfWidth,
        child: card,
      );
    }).toList();

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: items,
    );
  }
}

class _LegacyFieldsCard extends StatelessWidget {
  const _LegacyFieldsCard(
      {required this.slugs, required this.values});
  final List<String> slugs;
  final Map<String, dynamic> values;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Campos legacy',
                  style: AppFonts.geist(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctNavy)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ctSurface2,
                  border: Border.all(color: AppColors.ctBorder),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('Deprecado',
                    style: AppFonts.geist(
                        fontSize: 10,
                        color: AppColors.ctText2)
                      .copyWith(
                        fontStyle: FontStyle.italic,
                        decoration: TextDecoration.lineThrough)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...slugs.map((slug) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 160,
                      child: Text(slug,
                          style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              color: Color(0xFF475569))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(values[slug]?.toString() ?? '—',
                          style: AppFonts.geist(
                              fontSize: 12, color: AppColors.ctNavy)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Messages Block ────────────────────────────────────────────────────────────

class _MessagesBlock extends StatelessWidget {
  const _MessagesBlock({required this.exec});
  final Map<String, dynamic> exec;

  @override
  Widget build(BuildContext context) {
    final rawMessages = exec['messages'] as List? ?? [];
    final messages = rawMessages
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .toList();

    if (messages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_rounded,
                          size: 16, color: Color(0xFF25D366)),
                      const SizedBox(width: 8),
                      Text('Conversación relacionada',
                          style: AppFonts.onest(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctNavy,
                            letterSpacing: -0.02,
                          )),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                      '${messages.length} mensajes · todos los archivos quedaron registrados',
                      style: AppFonts.geist(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.arrow_outward_rounded, size: 12),
              label: const Text('Abrir hilo completo'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.ctText2,
                side: const BorderSide(color: AppColors.ctBorder),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                textStyle:
                    AppFonts.geist(fontSize: 12, fontWeight: FontWeight.w600),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MessagesThread(messages: messages),
      ],
    );
  }
}
