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

      // The API may return flow definition nested or at top level
      final flowRaw = (raw['flow'] as Map?)?.cast<String, dynamic>();
      Map<String, dynamic> flow;

      if (flowRaw != null && flowRaw.isNotEmpty) {
        flow = flowRaw;
      } else {
        // Fetch flow definition separately using flow_slug
        final slug = raw['flow_slug'] as String? ??
            raw['flowSlug'] as String? ??
            '';
        if (slug.isNotEmpty) {
          try {
            flow = await FlowsApi.getFlow(tenantId: tenantId, flowId: slug);
          } catch (_) {
            flow = _fallbackFlow(raw);
          }
        } else {
          flow = _fallbackFlow(raw);
        }
      }

      setState(() {
        _exec = raw;
        _flow = flow;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  /// Build a minimal flow map from execution data when no definition is available.
  Map<String, dynamic> _fallbackFlow(Map<String, dynamic> exec) {
    return {
      'slug': exec['flow_slug'] ?? exec['flowSlug'] ?? '',
      'name': exec['flow_name'] ?? exec['flowName'] ?? 'Flujo',
      'description': '',
      'type': exec['flow_type'] ?? exec['flowType'] ?? 'conversacional',
      'worker': exec['worker'] ?? {},
      'fields': exec['fields'] ?? [],
      'behavior': exec['behavior'] ?? {'onComplete': [], 'emits': []},
    };
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
      body: Column(
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
                        LineageBreadcrumb(exec: exec, flow: flow),
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
      ),
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

class _FieldsBlock extends StatelessWidget {
  const _FieldsBlock({required this.exec, required this.flow});
  final Map<String, dynamic> exec;
  final Map<String, dynamic> flow;

  @override
  Widget build(BuildContext context) {
    final rawFields = flow['fields'] as List? ?? [];
    final fields = rawFields
        .whereType<Map>()
        .map((f) => f.cast<String, dynamic>())
        .toList();

    final values = (exec['values'] as Map?)?.cast<String, dynamic>() ?? {};
    final pending = (exec['pending'] as List?)?.cast<String>() ?? [];
    final inheritedValues = (exec['inherited_values'] as Map?)?.cast<String, dynamic>() ??
        (exec['inheritedValues'] as Map?)?.cast<String, dynamic>() ?? {};

    final progress = (exec['progress'] as Map?)?.cast<String, dynamic>() ?? {};
    final filled = (progress['filled'] as num?)?.toInt() ?? 0;
    final total = (progress['total'] as num?)?.toInt() ?? 0;

    // Legacy fields: in values but not in flow.fields
    final knownSlugs = fields.map((f) => f['slug'] as String? ?? '').toSet();
    final legacySlugs = values.keys.where((k) => !knownSlugs.contains(k)).toList();

    if (fields.isEmpty && values.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspaces_outline,
              size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 8),
          Text('Este flujo no tiene campos definidos',
              style: AppFonts.geist(
                  fontSize: 14,
                  color: const Color(0xFF94A3B8))
                .copyWith(fontStyle: FontStyle.italic)),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
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
                  Text(
                      '$filled de $total requeridos · definidos en el flujo',
                      style: AppFonts.geist(
                          fontSize: 12, color: const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (ctx, constraints) {
            final totalWidth = constraints.maxWidth;
            final gap = 14.0;

            return _WrapGrid(
              fields: fields,
              values: values,
              pending: pending,
              inheritedValues: inheritedValues,
              totalWidth: totalWidth,
              gap: gap,
            );
          },
        ),
        if (legacySlugs.isNotEmpty) ...[
          const SizedBox(height: 22),
          _LegacyFieldsCard(slugs: legacySlugs, values: values),
        ],
      ],
    );
  }
}

class _WrapGrid extends StatelessWidget {
  const _WrapGrid({
    required this.fields,
    required this.values,
    required this.pending,
    required this.inheritedValues,
    required this.totalWidth,
    required this.gap,
  });

  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> values;
  final List<String> pending;
  final Map<String, dynamic> inheritedValues;
  final double totalWidth;
  final double gap;

  @override
  Widget build(BuildContext context) {
    // Simulate a 2-column grid using Wrap
    final halfWidth = (totalWidth - gap) / 2;

    final List<Widget> items = fields.map((field) {
      final slug = field['slug'] as String? ?? '';
      final value = values[slug] ?? inheritedValues[slug];
      final isPending = pending.contains(slug);
      final isInherited = !values.containsKey(slug) && inheritedValues.containsKey(slug);
      final card = FieldCard(
        field: field,
        value: value,
        isPending: isPending,
        isInherited: isInherited,
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
