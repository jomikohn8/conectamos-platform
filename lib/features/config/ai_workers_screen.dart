import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ai_workers_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kColorPalette = [
  '#2DD4BF', '#818CF8', '#FB923C', '#F472B6', '#34D399', '#60A5FA',
];

const _kTypeConfig = {
  'logistics':   (label: 'Logística', bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF)),
  'sales':       (label: 'Ventas',    bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9)),
  'collections': (label: 'Cobranza', bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
  'custom':      (label: 'Custom',   bg: Color(0xFFF3F4F6), fg: Color(0xFF374151)),
};

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isEmpty ? '?' : name[0].toUpperCase();
}

String _dioError(Object e) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final d = data['detail'];
      if (d != null) return 'Error: $d';
    }
    final s = e.response?.statusCode;
    if (s != null) return 'Error $s al procesar la solicitud';
  }
  return e.toString();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AiWorkersScreen extends ConsumerStatefulWidget {
  const AiWorkersScreen({super.key});

  @override
  ConsumerState<AiWorkersScreen> createState() => _AiWorkersScreenState();
}

class _AiWorkersScreenState extends ConsumerState<AiWorkersScreen> {
  List<Map<String, dynamic>> _myWorkers = [];
  List<Map<String, dynamic>> _catalog   = [];
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final results = await Future.wait([
        AiWorkersApi.listWorkers(tenantId: tenantId),
        AiWorkersApi.listCatalog(tenantId: tenantId),
      ]);
      if (!mounted) return;
      setState(() {
        _myWorkers = results[0];
        _catalog   = results[1];
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _dioError(e); });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> worker) async {
    final id       = worker['id'] as String? ?? '';
    final isActive = worker['is_active'] as bool? ?? false;
    // Optimistic update
    setState(() {
      _myWorkers = [
        for (final w in _myWorkers)
          if ((w['id'] as String?) == id)
            {...w, 'is_active': !isActive}
          else
            w,
      ];
    });
    try {
      await AiWorkersApi.updateWorker(
        tenantWorkerId: id,
        isActive: !isActive,
      );
    } catch (e) {
      if (!mounted) return;
      // Revert
      setState(() {
        _myWorkers = [
          for (final w in _myWorkers)
            if ((w['id'] as String?) == id)
              {...w, 'is_active': isActive}
            else
              w,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  void _openRename(Map<String, dynamic> worker) async {
    await showDialog(
      context: context,
      builder: (_) => _RenameDialog(
        worker: worker,
        tenantId: ref.read(activeTenantIdProvider),
        onSaved: _fetchAll,
      ),
    );
  }

  void _openCatalog() async {
    final messenger = ScaffoldMessenger.of(context);
    await showDialog(
      context: context,
      builder: (_) => _CatalogDialog(
        catalog: _catalog,
        myWorkers: _myWorkers,
        tenantId: ref.read(activeTenantIdProvider),
        onContracted: () async {
          await _fetchAll();
          messenger.showSnackBar(const SnackBar(
            content: Text('Worker contratado exitosamente'),
            backgroundColor: AppColors.ctOk,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBar(loading: _loading, onAdd: _openCatalog),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.ctTeal, strokeWidth: 2,
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctDanger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          _GhostBtn(label: 'Reintentar', onTap: _fetchAll),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: _myWorkers.isEmpty
                          ? _EmptyState(onOpenCatalog: _openCatalog)
                          : _WorkersBody(
                              workers: _myWorkers,
                              onToggle: _toggleActive,
                              onRename: _openRename,
                            ),
                    ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.loading, required this.onAdd});
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
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
                  'Mis Workers',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Workers de IA contratados para tu operación',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryBtn(
            label: '+ Contratar worker',
            onTap: onAdd,
            disabled: loading,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onOpenCatalog});
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No tienes workers contratados aún.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText2,
              ),
            ),
            const SizedBox(height: 14),
            _PrimaryBtn(label: 'Ver catálogo', onTap: onOpenCatalog),
          ],
        ),
      ),
    );
  }
}

// ── Workers body ──────────────────────────────────────────────────────────────

class _WorkersBody extends StatelessWidget {
  const _WorkersBody({
    required this.workers,
    required this.onToggle,
    required this.onRename,
  });
  final List<Map<String, dynamic>> workers;
  final void Function(Map<String, dynamic>) onToggle;
  final void Function(Map<String, dynamic>) onRename;

  static const _headerStyle = TextStyle(
    fontFamily: 'Geist',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.ctText2,
    letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('WORKER',      style: _headerStyle)),
                Expanded(flex: 2, child: Text('TIPO',        style: _headerStyle)),
                Expanded(flex: 3, child: Text('WEBHOOK',     style: _headerStyle)),
                Expanded(flex: 1, child: Text('ESTADO',      style: _headerStyle)),
                Expanded(flex: 2, child: Text('ACCIONES',    style: _headerStyle)),
              ],
            ),
          ),
          // Rows
          ...workers.asMap().entries.map((entry) {
            final isLast = entry.key == workers.length - 1;
            return Column(
              children: [
                _WorkerRow(
                  worker: entry.value,
                  onToggle: () => onToggle(entry.value),
                  onRename: () => onRename(entry.value),
                ),
                if (!isLast)
                  const Divider(height: 1, color: AppColors.ctBorder),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Worker row ────────────────────────────────────────────────────────────────

class _WorkerRow extends StatefulWidget {
  const _WorkerRow({
    required this.worker,
    required this.onToggle,
    required this.onRename,
  });
  final Map<String, dynamic> worker;
  final VoidCallback onToggle;
  final VoidCallback onRename;

  @override
  State<_WorkerRow> createState() => _WorkerRowState();
}

class _WorkerRowState extends State<_WorkerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w            = widget.worker;
    final displayName  = w['display_name'] as String? ?? w['catalog_name'] as String? ?? '—';
    final description  = w['catalog_description'] as String? ?? '';
    final colorHex     = w['catalog_color'] as String? ?? _kColorPalette.first;
    final workerType   = w['catalog_worker_type'] as String? ?? 'custom';
    final webhookUrl   = w['catalog_webhook_url'] as String? ?? '';
    final isActive     = w['is_active'] as bool? ?? false;
    final typeEntry    = _kTypeConfig[workerType] ?? _kTypeConfig['custom']!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── WORKER ────────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _hexColor(colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            description,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              color: AppColors.ctText2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── TIPO ──────────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypeBadge(
                  label: typeEntry.label,
                  bg: typeEntry.bg,
                  fg: typeEntry.fg,
                ),
              ),
            ),

            // ── WEBHOOK ───────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Text(
                webhookUrl,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ── ESTADO ────────────────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.ctOkBg : AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.ctOkText : AppColors.ctText2,
                    ),
                  ),
                ),
              ),
            ),

            // ── ACCIONES ──────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    label: 'Renombrar',
                    color: AppColors.ctInfo,
                    onTap: widget.onRename,
                  ),
                  const SizedBox(width: 6),
                  _ActionBtn(
                    label: isActive ? 'Desactivar' : 'Activar',
                    color: isActive ? AppColors.ctDanger : AppColors.ctOk,
                    onTap: widget.onToggle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Rename dialog ─────────────────────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({
    required this.worker,
    required this.tenantId,
    required this.onSaved,
  });
  final Map<String, dynamic> worker;
  final String tenantId;
  final Future<void> Function() onSaved;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _nameCtrl;
  bool    _saving   = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final current = widget.worker['display_name'] as String? ??
        widget.worker['catalog_name'] as String? ?? '';
    _nameCtrl = TextEditingController(text: current);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMsg = 'El nombre no puede estar vacío.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final id = widget.worker['id'] as String? ?? '';
      await AiWorkersApi.updateWorker(
        tenantWorkerId: id,
        displayName: name,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onSaved();
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _errorMsg = _dioError(e); });
      messenger.showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final originalName = widget.worker['catalog_name'] as String? ?? '';

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Renombrar worker',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              if (originalName.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Nombre original: $originalName',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Nombre personalizado',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _nameCtrl,
                autofocus: true,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
                decoration: InputDecoration(
                  hintText: 'Ej: Worker Logística Norte',
                  hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText3,
                  ),
                  filled: true,
                  fillColor: AppColors.ctSurface2,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.ctBorder2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.ctBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.ctTeal, width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _save(),
              ),
              if (_errorMsg != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ctRedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctRedText,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostBtn(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _saving
                      ? _loadingBtn()
                      : _PrimaryBtn(label: 'Guardar', onTap: _save),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Catalog dialog ────────────────────────────────────────────────────────────

class _CatalogDialog extends StatefulWidget {
  const _CatalogDialog({
    required this.catalog,
    required this.myWorkers,
    required this.tenantId,
    required this.onContracted,
  });
  final List<Map<String, dynamic>> catalog;
  final List<Map<String, dynamic>> myWorkers;
  final String tenantId;
  final Future<void> Function() onContracted;

  @override
  State<_CatalogDialog> createState() => _CatalogDialogState();
}

class _CatalogDialogState extends State<_CatalogDialog> {
  final Set<String> _contracting = {};

  bool _isContracted(String catalogId) => widget.myWorkers.any(
    (w) => (w['catalog_worker_id'] as String?) == catalogId,
  );

  Future<void> _contract(String catalogId) async {
    if (_contracting.contains(catalogId)) return;
    setState(() => _contracting.add(catalogId));
    final messenger = ScaffoldMessenger.of(context);
    try {
      await AiWorkersApi.contractWorker(
        tenantId: widget.tenantId,
        catalogWorkerId: catalogId,
      );
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onContracted();
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _contracting.remove(catalogId));
      final status = e.response?.statusCode;
      final String msg;
      final Color color;
      if (status == 409) {
        msg   = 'Ya tienes este worker contratado.';
        color = AppColors.ctWarn;
      } else if (status == 400) {
        final data = e.response?.data;
        msg   = (data is Map && data['detail'] != null)
            ? 'Error: ${data['detail']}'
            : 'Solicitud inválida.';
        color = AppColors.ctDanger;
      } else {
        msg   = _dioError(e);
        color = AppColors.ctDanger;
      }
      messenger.showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: color,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _contracting.remove(catalogId));
      messenger.showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Catálogo de Workers',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Selecciona un worker para agregarlo a tu operación.',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.ctBorder),

            // Catalog list
            Flexible(
              child: widget.catalog.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No hay workers en el catálogo.',
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.catalog.length,
                      itemBuilder: (_, i) {
                        final item        = widget.catalog[i];
                        final catalogId   = item['id'] as String? ?? '';
                        final name        = item['name'] as String? ?? item['display_name'] as String? ?? '—';
                        final description = item['description'] as String? ?? '';
                        final colorHex    = item['color'] as String? ?? _kColorPalette[i % _kColorPalette.length];
                        final isPublished = item['is_published'] as bool? ?? true;
                        final contracted  = _isContracted(catalogId);
                        final contracting = _contracting.contains(catalogId);

                        final rawSkills = item['skills'] as List<dynamic>? ?? [];
                        final skills    = rawSkills.map((s) => s.toString()).toList();

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: AppColors.ctSurface,
                            border: Border.all(color: AppColors.ctBorder),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _hexColor(colorHex),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _initials(name),
                                  style: const TextStyle(
                                    fontFamily: 'Geist',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ctText,
                                      ),
                                    ),
                                    if (description.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        description,
                                        style: const TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 12,
                                          color: AppColors.ctText2,
                                        ),
                                      ),
                                    ],
                                    if (skills.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: skills.map((s) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.ctSurface2,
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: AppColors.ctBorder),
                                            ),
                                            child: Text(
                                              s,
                                              style: const TextStyle(
                                                fontFamily: 'Geist',
                                                fontSize: 11,
                                                color: AppColors.ctText2,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Action
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (!isPublished)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.ctSurface2,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.ctBorder),
                                      ),
                                      child: const Text(
                                        'Próximamente',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.ctText2,
                                        ),
                                      ),
                                    )
                                  else if (contracted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: AppColors.ctOkBg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'Contratado',
                                        style: TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.ctOkText,
                                        ),
                                      ),
                                    )
                                  else
                                    contracting
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.ctTeal,
                                            ),
                                          )
                                        : _PrimaryBtn(
                                            label: 'Contratar',
                                            onTap: () => _contract(catalogId),
                                          ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, color: AppColors.ctBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostBtn(
                    label: 'Cerrar',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── Loading button helper ─────────────────────────────────────────────────────

Widget _loadingBtn() => Container(
  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
  decoration: BoxDecoration(
    color: AppColors.ctTeal, borderRadius: BorderRadius.circular(8),
  ),
  child: const SizedBox(
    width: 16, height: 16,
    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctNavy),
  ),
);

// ── Button helpers ────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onTap,
    this.disabled = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.disabled
                ? AppColors.ctBorder2
                : _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.disabled ? AppColors.ctText3 : AppColors.ctNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatefulWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
