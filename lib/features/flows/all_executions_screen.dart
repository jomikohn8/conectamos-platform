import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/overview_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_shell.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _fmtElapsed(int? seconds) {
  if (seconds == null) return '—';
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
  return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
}

String _elapsedSince(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'hace ${diff.inSeconds}s';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
  return 'hace ${diff.inHours}h';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AllExecutionsScreen extends ConsumerStatefulWidget {
  const AllExecutionsScreen({super.key});

  @override
  ConsumerState<AllExecutionsScreen> createState() =>
      _AllExecutionsScreenState();
}

class _AllExecutionsScreenState extends ConsumerState<AllExecutionsScreen> {
  bool _loading = true;
  String? _error;
  List<dynamic> _executions = [];
  DateTime? _lastFetch;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(topbarTitleProvider.notifier).state = 'Ejecuciones';
      ref.read(topbarSubtitleProvider.notifier).state = null;
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId.isNotEmpty) {
        _load();
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (t) {
          if (mounted) _load();
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final data = await OverviewApi.getFlowExecutionsDebug(tenantId: tenantId);
      setState(() {
        _executions = List<dynamic>.from(data['executions'] ?? []);
        _lastFetch = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (next.isNotEmpty) _load();
    });

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Topbar row ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Todas las ejecuciones',
                    style: AppFonts.onest(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                ),
                if (_lastFetch != null)
                  Text(
                    'Act. ${_elapsedSince(_lastFetch!)}',
                    style: AppFonts.geist(
                        fontSize: 11, color: AppColors.ctText3),
                  ),
                const SizedBox(width: 4),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ctTeal,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded,
                            size: 16, color: AppColors.ctText3),
                    onPressed: _loading ? null : () => _load(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ── Body ────────────────────────────────────────────────────────────
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _executions.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ctTeal),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: AppFonts.geist(
                    fontSize: 13, color: AppColors.ctDanger)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _load,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }
    if (_executions.isEmpty) {
      return Center(
        child: Text(
          'Sin ejecuciones registradas',
          style: AppFonts.geist(fontSize: 13, color: AppColors.ctText3),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      itemCount: _executions.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 6),
      itemBuilder: (context2, i) {
        final exec = _executions[i] as Map<String, dynamic>;
        return _ExecutionRow(
          execution: exec,
          onTap: () => context.go('/flows/runs/${exec['execution_id'] ?? exec['id']}'),
        );
      },
    );
  }
}

// ── _ExecutionRow ─────────────────────────────────────────────────────────────

class _ExecutionRow extends StatelessWidget {
  const _ExecutionRow({required this.execution, required this.onTap});

  final Map<String, dynamic> execution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final flowDef = execution['flow_definition'] as Map<String, dynamic>?;
    final operator_ = execution['operator'] as Map<String, dynamic>?;
    final status = execution['status'] as String? ?? 'unknown';
    final elapsedSeconds = execution['elapsed_seconds'] as int?;
    final fieldsCaptured =
        (execution['fields_captured'] as Map?)
            ?.map((k, v) => MapEntry(k.toString(), v)) ??
        <String, dynamic>{};

    final fieldsExpected = flowDef != null
        ? List<Map<String, dynamic>>.from(
            (flowDef['fields_expected'] as List? ?? [])
                .map((f) => Map<String, dynamic>.from(f as Map)),
          )
        : <Map<String, dynamic>>[];

    final captured = fieldsExpected.where((f) {
      final v = fieldsCaptured[f['key']];
      return v != null && v.toString().isNotEmpty;
    }).length;

    final flowName = flowDef?['name'] as String?;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      color: AppColors.ctSurface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Main info ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flowName ?? (flowDef != null ? 'Sin nombre' : 'Flow eliminado'),
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.geist(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: flowDef != null
                            ? AppColors.ctText
                            : AppColors.ctText3,
                      ).copyWith(
                        fontStyle: flowDef == null
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: AppColors.ctText3),
                        const SizedBox(width: 4),
                        Text(
                          operator_?['name'] as String? ?? 'Sin operador',
                          style: AppFonts.geist(
                              fontSize: 11, color: AppColors.ctText3),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.timer_outlined,
                            size: 12, color: AppColors.ctText3),
                        const SizedBox(width: 4),
                        Text(
                          _fmtElapsed(elapsedSeconds),
                          style: AppFonts.geist(
                              fontSize: 11, color: AppColors.ctText3),
                        ),
                        if (fieldsExpected.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Text(
                            '$captured/${fieldsExpected.length} campos',
                            style: AppFonts.geist(
                                fontSize: 11, color: AppColors.ctTealDark),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // ── Status badge + chevron ────────────────────────────────────
              _StatusBadge(status: status),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  size: 16, color: AppColors.ctText3),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _StatusBadge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'active' || 'in_progress' => (AppColors.ctTealLight, AppColors.ctTealDark),
      'completed' => (AppColors.ctOkBg, AppColors.ctOkText),
      'abandoned' => (AppColors.ctSurface2, AppColors.ctText3),
      'paused' => (AppColors.ctWarnBg, AppColors.ctWarnText),
      _ => (AppColors.ctSurface2, AppColors.ctText2),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        style: AppFonts.geist(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}
