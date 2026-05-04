import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/executions_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/app_shell.dart';

// ── _ColDef ───────────────────────────────────────────────────────────────────

class _ColDef {
  final String id;
  final String label;
  bool visible;
  _ColDef(this.id, this.label, {this.visible = true});
}

// ── _DateHeader sentinel ──────────────────────────────────────────────────────

class _DateHeader {
  final String label;
  const _DateHeader(this.label);
}

// ── Top-level helpers ─────────────────────────────────────────────────────────

double _colWidth(String id) => switch (id) {
  'worker'   => 130,
  'status'   => 110,
  'operator' => 130,
  'channel'  => 90,
  'created'  => 110,
  'elapsed'  => 90,
  'progress' => 90,
  _          => 100,
};

String _fmtElapsed(int? seconds) {
  if (seconds == null) return '—';
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
  return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
}

String _fmtTime(DateTime dt) {
  final local = dt.toLocal();
  final h = local.hour.toString().padLeft(2, '0');
  final m = local.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _dateGroupLabel(DateTime dt) {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yest  = today.subtract(const Duration(days: 1));
  final d     = DateTime(dt.year, dt.month, dt.day);
  if (d == today) return 'Hoy';
  if (d == yest)  return 'Ayer';
  const mo = ['Ene','Feb','Mar','Abr','May','Jun',
               'Jul','Ago','Sep','Oct','Nov','Dic'];
  return '${dt.day} ${mo[dt.month - 1]} ${dt.year}';
}

String _elapsedSince(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'hace ${d.inSeconds}s';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes}m';
  return 'hace ${d.inHours}h';
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AllExecutionsScreen extends ConsumerStatefulWidget {
  const AllExecutionsScreen({super.key});

  @override
  ConsumerState<AllExecutionsScreen> createState() =>
      _AllExecutionsScreenState();
}

class _AllExecutionsScreenState extends ConsumerState<AllExecutionsScreen> {
  bool   _loading = true;
  String? _error;
  List<Map<String, dynamic>> _executions = [];
  int    _total  = 0;
  int    _page   = 1;
  static const int _limit = 25;

  String _sortCol = 'created_at';
  String _sortDir = 'desc';
  String _grouping = 'date'; // 'date' | 'none'

  late List<_ColDef> _columns;
  bool _showColumnPicker = false;
  Timer? _refreshTimer;
  DateTime? _lastFetch;

  @override
  void initState() {
    super.initState();
    _columns = [
      _ColDef('flow',     'Flujo',    visible: true),
      _ColDef('worker',   'Worker',   visible: true),
      _ColDef('status',   'Estado',   visible: true),
      _ColDef('operator', 'Operador', visible: true),
      _ColDef('channel',  'Canal',    visible: true),
      _ColDef('created',  'Creada',   visible: true),
      _ColDef('elapsed',  'Tiempo',   visible: false),
      _ColDef('progress', 'Campos',   visible: false),
    ];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(topbarTitleProvider.notifier).state = 'Ejecuciones';
      ref.read(topbarSubtitleProvider.notifier).state = null;
      final tenantId = ref.read(activeTenantIdProvider);
      if (tenantId.isNotEmpty) {
        _load();
        _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
      final data = await ExecutionsApi.listExecutions(
        tenantId: tenantId,
        sortCol:  _sortCol,
        sortDir:  _sortDir,
        page:     _page,
        limit:    _limit,
      );
      final raw = data['items'] ?? data['executions'] ?? data['data'] ?? [];
      setState(() {
        _executions = List<Map<String, dynamic>>.from(
          (raw as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
        );
        _total     = (data['total'] as num?)?.toInt() ?? _executions.length;
        _lastFetch = DateTime.now();
        _loading   = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSort(String apiCol) {
    setState(() {
      if (_sortCol == apiCol) {
        _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      } else {
        _sortCol = apiCol;
        _sortDir = 'desc';
      }
      _page = 1;
    });
    _load();
  }

  String _apiCol(String colId) => switch (colId) {
    'flow'     => 'flow_name',
    'status'   => 'status',
    'operator' => 'operator_name',
    'created'  => 'created_at',
    'elapsed'  => 'elapsed_seconds',
    _          => colId,
  };

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(activeTenantIdProvider, (_, next) {
      if (next.isNotEmpty) { _page = 1; _load(); }
    });

    final totalPages = _total > 0 ? (_total / _limit).ceil() : 1;

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopbar(),
              const SizedBox(height: 12),
              _buildTableHeader(),
              Expanded(child: _buildBody()),
              if (_total > _limit)
                _buildPaginationFooter(totalPages),
            ],
          ),
          // Dismiss layer for column picker
          if (_showColumnPicker)
            GestureDetector(
              onTap: () => setState(() => _showColumnPicker = false),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          // Column picker card
          if (_showColumnPicker)
            Positioned(
              top: 58,
              right: 24,
              child: _buildColumnPickerCard(),
            ),
        ],
      ),
    );
  }

  // ── Topbar ────────────────────────────────────────────────────────────────

  Widget _buildTopbar() {
    final visCount = _columns.where((c) => c.visible).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          Text(
            'Todas las ejecuciones',
            style: AppFonts.onest(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
            ),
          ),
          if (!_loading && _total > 0) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.ctSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.ctBorder),
              ),
              child: Text(
                '$_total',
                style: AppFonts.geist(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText2,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Grouping toggle
          _TopbarChip(
            icon: Icons.calendar_today_outlined,
            label: _grouping == 'date' ? 'Por fecha' : 'Sin agrupar',
            active: _grouping == 'date',
            onTap: () => setState(
                () => _grouping = _grouping == 'date' ? 'none' : 'date'),
          ),
          const SizedBox(width: 8),
          // Column picker toggle
          _TopbarChip(
            icon: Icons.view_column_outlined,
            label: '$visCount col.',
            active: _showColumnPicker,
            onTap: () =>
                setState(() => _showColumnPicker = !_showColumnPicker),
          ),
          const SizedBox(width: 12),
          // Last-fetch label
          if (_lastFetch != null)
            Text(
              'Act. ${_elapsedSince(_lastFetch!)}',
              style: AppFonts.geist(fontSize: 11, color: AppColors.ctText3),
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
              onPressed: _loading ? null : _load,
            ),
          ),
        ],
      ),
    );
  }

  // ── Table header ──────────────────────────────────────────────────────────

  Widget _buildTableHeader() {
    final visible = _columns.where((c) => c.visible).toList();
    return Container(
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          ...visible.map((col) {
            final apiField  = _apiCol(col.id);
            final isSorted  = _sortCol == apiField;
            final isFlow    = col.id == 'flow';
            final cell = InkWell(
              onTap: () => _onSort(apiField),
              child: SizedBox(
                height: 36,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          col.label,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.geist(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSorted
                                ? AppColors.ctText
                                : AppColors.ctText2,
                          ),
                        ),
                      ),
                      if (isSorted) ...[
                        const SizedBox(width: 3),
                        Icon(
                          _sortDir == 'asc'
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 10,
                          color: AppColors.ctTeal,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
            return isFlow
                ? Expanded(child: cell)
                : SizedBox(width: _colWidth(col.id), child: cell);
          }),
          // Chevron placeholder
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

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
            TextButton(onPressed: _load, child: const Text('Reintentar')),
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

    final items = _groupedItems();

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(
          left:   BorderSide(color: AppColors.ctBorder),
          right:  BorderSide(color: AppColors.ctBorder),
          bottom: BorderSide(color: AppColors.ctBorder),
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft:  Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        child: ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final item = items[i];
            if (item is _DateHeader) return _buildDateSeparator(item.label);
            return _buildExecutionRow(item as Map<String, dynamic>);
          },
        ),
      ),
    );
  }

  List<dynamic> _groupedItems() {
    if (_grouping == 'none') return _executions;

    final result   = <dynamic>[];
    String? lastLbl;
    for (final exec in _executions) {
      final raw = exec['created_at'] as String?;
      String lbl = '—';
      if (raw != null) {
        try { lbl = _dateGroupLabel(DateTime.parse(raw)); } catch (_) {}
      }
      if (lbl != lastLbl) {
        result.add(_DateHeader(lbl));
        lastLbl = lbl;
      }
      result.add(exec);
    }
    return result;
  }

  Widget _buildDateSeparator(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface2,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Text(
        label,
        style: AppFonts.geist(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText2,
        ),
      ),
    );
  }

  Widget _buildExecutionRow(Map<String, dynamic> exec) {
    final id = exec['execution_id'] as String?
        ?? exec['id'] as String?
        ?? '';

    // New API: flow_name is a flat string.
    // Fallback to nested flow_definition/flow for backward compat.
    final flowName = exec['flow_name'] as String?
        ?? (exec['flow_definition'] as Map<String, dynamic>?)?['name'] as String?
        ?? (exec['flow'] as Map<String, dynamic>?)?['name'] as String?;

    final operator_ = exec['operator'] as Map<String, dynamic>?;
    final worker_   = exec['worker']   as Map<String, dynamic>?;
    final status    = exec['status']   as String? ?? 'unknown';

    // New API: channel is a nested object { id, channel_type }.
    final channelObj  = exec['channel'] as Map<String, dynamic>?;
    final channelType = channelObj?['channel_type'] as String?
        ?? exec['channel_type'] as String?;

    final createdStr = exec['created_at'] as String?;
    final elapsedSec = exec['elapsed_seconds'] as int?;

    // New API: fields_progress: { total: N, filled: M }.
    final progressMap = exec['fields_progress'] as Map<String, dynamic>?;
    final total    = (progressMap?['total']  as num?)?.toInt() ?? 0;
    final captured = (progressMap?['filled'] as num?)?.toInt() ?? 0;

    DateTime? createdDt;
    if (createdStr != null) {
      try { createdDt = DateTime.parse(createdStr); } catch (_) {}
    }

    final visible = _columns.where((c) => c.visible).toList();

    return InkWell(
      onTap: () => context.go('/executions/$id'),
      child: Container(
        height: 44,
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
        ),
        child: Row(
          children: [
            ...visible.map((col) {
              final isFlow = col.id == 'flow';
              final cell   = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _cellContent(
                    colId:       col.id,
                    flowName:    flowName,
                    operator_:   operator_,
                    worker_:     worker_,
                    status:      status,
                    channelType: channelType,
                    createdDt:   createdDt,
                    elapsedSec:  elapsedSec,
                    captured:    captured,
                    total:       total,
                  ),
                ),
              );
              return isFlow
                  ? Expanded(child: cell)
                  : SizedBox(width: _colWidth(col.id), child: cell);
            }),
            const SizedBox(
              width: 32,
              child: Center(
                child: Icon(Icons.chevron_right_rounded,
                    size: 14, color: AppColors.ctText3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cellContent({
    required String colId,
    required String? flowName,
    required Map<String, dynamic>? operator_,
    required Map<String, dynamic>? worker_,
    required String status,
    required String? channelType,
    required DateTime? createdDt,
    required int? elapsedSec,
    required int captured,
    required int total,
  }) {
    switch (colId) {
      case 'flow':
        return Text(
          flowName ?? '—',
          overflow: TextOverflow.ellipsis,
          style: AppFonts.geist(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: flowName != null ? AppColors.ctText : AppColors.ctText3,
          ).copyWith(
            fontStyle: flowName == null ? FontStyle.italic : FontStyle.normal,
          ),
        );
      case 'worker':
        final name = worker_?['name'] as String?
            ?? worker_?['id'] as String?
            ?? '—';
        return Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
        );
      case 'status':
        return _StatusBadge(status: status);
      case 'operator':
        final name = operator_?['name'] as String? ?? '—';
        return Text(
          name,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
        );
      case 'channel':
        return _ChannelBadge(channelType: channelType);
      case 'created':
        return Text(
          createdDt != null ? _fmtTime(createdDt) : '—',
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
        );
      case 'elapsed':
        return Text(
          _fmtElapsed(elapsedSec),
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
        );
      case 'progress':
        if (total == 0) {
          return Text('—',
              style: AppFonts.geist(fontSize: 12, color: AppColors.ctText3));
        }
        return Text(
          '$captured/$total',
          style: AppFonts.geist(
            fontSize: 12,
            color: captured == total
                ? AppColors.ctOkText
                : AppColors.ctTealDark,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  Widget _buildPaginationFooter(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          Text(
            'Pág. $_page de $totalPages  ·  $_total resultados',
            style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: (_page <= 1 || _loading)
                ? null
                : () { setState(() => _page--); _load(); },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ctText2,
              side: const BorderSide(color: AppColors.ctBorder2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle: AppFonts.geist(fontSize: 12),
            ),
            child: const Text('← Anterior'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: (_page >= totalPages || _loading)
                ? null
                : () { setState(() => _page++); _load(); },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ctText2,
              side: const BorderSide(color: AppColors.ctBorder2),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              textStyle: AppFonts.geist(fontSize: 12),
            ),
            child: const Text('Siguiente →'),
          ),
        ],
      ),
    );
  }

  // ── Column picker card ────────────────────────────────────────────────────

  Widget _buildColumnPickerCard() {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(10),
      shadowColor: Colors.black12,
      child: Container(
        width: 210,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ctSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.ctBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              child: Text(
                'Columnas visibles',
                style: AppFonts.geist(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText2,
                ),
              ),
            ),
            ..._columns.map((col) => InkWell(
              onTap: () => setState(() => col.visible = !col.visible),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: col.visible
                            ? AppColors.ctTeal
                            : AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: col.visible
                              ? AppColors.ctTeal
                              : AppColors.ctBorder2,
                        ),
                      ),
                      child: col.visible
                          ? const Icon(Icons.check_rounded,
                              size: 10, color: AppColors.ctNavy)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      col.label,
                      style: AppFonts.geist(
                          fontSize: 13, color: AppColors.ctText),
                    ),
                  ],
                ),
              ),
            )),
          ],
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
    final (bg, fg, label) = switch (status) {
      'active' || 'in_progress' =>
          (AppColors.ctTealLight, AppColors.ctTealDark, 'activa'),
      'completed' =>
          (AppColors.ctOkBg, AppColors.ctOkText, 'completada'),
      'pending' =>
          (AppColors.ctInfoBg, AppColors.ctInfoText, 'pendiente'),
      'pending_dashboard' || 'pending_review' =>
          (AppColors.ctInfoBg, AppColors.ctInfoText, 'en revisión'),
      'paused' =>
          (AppColors.ctWarnBg, AppColors.ctWarnText, 'pausada'),
      'abandoned' =>
          (AppColors.ctSurface2, AppColors.ctText3, 'abandonada'),
      'cancelled' =>
          (AppColors.ctSurface2, AppColors.ctText3, 'cancelada'),
      'failed' || 'error' =>
          (AppColors.ctRedBg, AppColors.ctRedText, 'error'),
      _ =>
          (AppColors.ctSurface2, AppColors.ctText2, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: AppFonts.geist(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── _ChannelBadge ─────────────────────────────────────────────────────────────

class _ChannelBadge extends StatelessWidget {
  const _ChannelBadge({required this.channelType});

  final String? channelType;

  @override
  Widget build(BuildContext context) {
    if (channelType == null) {
      return Text('—',
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText3));
    }
    final lc = channelType!.toLowerCase();
    final (color, label) = switch (lc) {
      'whatsapp' || 'wa' => (AppColors.ctWa, 'WA'),
      'telegram' || 'tg' => (AppColors.ctTg, 'TG'),
      _                  => (AppColors.ctText3, channelType!),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppFonts.geist(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── _TopbarChip ───────────────────────────────────────────────────────────────

class _TopbarChip extends StatefulWidget {
  const _TopbarChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_TopbarChip> createState() => _TopbarChipState();
}

class _TopbarChipState extends State<_TopbarChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.active
                ? AppColors.ctTealLight
                : (_hovered ? AppColors.ctSurface2 : AppColors.ctSurface),
            border: Border.all(
              color: widget.active ? AppColors.ctTeal : AppColors.ctBorder,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: widget.active
                    ? AppColors.ctTealDark
                    : AppColors.ctText2,
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: AppFonts.geist(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: widget.active
                      ? AppColors.ctTealDark
                      : AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
