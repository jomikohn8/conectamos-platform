import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ai_workers_api.dart';
import '../../core/api/flows_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kTypeConfig = {
  'logistics':   (label: 'Logística', bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF)),
  'sales':       (label: 'Ventas',    bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9)),
  'collections': (label: 'Cobranza', bg: Color(0xFFFEF3C7), fg: Color(0xFFB45309)),
  'custom':      (label: 'Custom',   bg: Color(0xFFF3F4F6), fg: Color(0xFF374151)),
};

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _hexColor(String? hex) {
  if (hex == null) return const Color(0xFF9CA3AF);
  try {
    final h = hex.replaceAll('#', '');
    if (h.length != 6) return const Color(0xFF9CA3AF);
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFF9CA3AF);
  }
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

class WorkflowsScreen extends ConsumerStatefulWidget {
  const WorkflowsScreen({super.key});

  @override
  ConsumerState<WorkflowsScreen> createState() => _WorkflowsScreenState();
}

class _WorkflowsScreenState extends ConsumerState<WorkflowsScreen> {
  List<Map<String, dynamic>> _flows   = [];
  List<Map<String, dynamic>> _workers = [];
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
        FlowsApi.listFlows(tenantId: tenantId),
        AiWorkersApi.listWorkers(tenantId: tenantId),
      ]);
      if (!mounted) return;
      setState(() {
        _flows   = results[0];
        _workers = results[1];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _dioError(e); });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> flow) async {
    final id       = flow['id'] as String? ?? '';
    final isActive = flow['is_active'] as bool? ?? false;
    // Optimistic update
    setState(() {
      _flows = [
        for (final f in _flows)
          if ((f['id'] as String?) == id)
            {...f, 'is_active': !isActive}
          else
            f,
      ];
    });
    try {
      await FlowsApi.updateFlow(flowId: id, isActive: !isActive);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF059669),
        content: Text(
          !isActive ? 'Flujo activado' : 'Flujo desactivado',
          style: const TextStyle(fontFamily: 'Geist', color: Colors.white),
        ),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      // Revert
      setState(() {
        _flows = [
          for (final f in _flows)
            if ((f['id'] as String?) == id)
              {...f, 'is_active': isActive}
            else
              f,
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.ctDanger,
        content: Text(
          _dioError(e),
          style: const TextStyle(fontFamily: 'Geist', color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _openForm({Map<String, dynamic>? flow}) {
    showDialog(
      context: context,
      builder: (_) => _FlowFormDialog(
        flow: flow,
        workers: _workers,
        onSaved: _fetchAll,
        tenantId: ref.read(activeTenantIdProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (next.isNotEmpty && next != prev) _fetchAll();
    });

    return Column(
      children: [
        _ActionBar(onNew: () => _openForm()),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
            _PrimaryButton(label: 'Reintentar', onTap: _fetchAll),
          ],
        ),
      );
    }
    if (_flows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'No hay flujos configurados aún',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText2,
              ),
            ),
            const SizedBox(height: 12),
            _PrimaryButton(label: '+ Crear primer flujo', onTap: () => _openForm()),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        children: _flows.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FlowCard(
              flow: entry.value,
              index: entry.key,
              onToggle: () => _toggleActive(entry.value),
              onEdit: () => _openForm(flow: entry.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onNew});
  final VoidCallback onNew;

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
                  'Flujos de trabajo',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Configura los flujos de reporte de tus operadores',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryButton(label: '+ Nuevo flujo', onTap: onNew),
        ],
      ),
    );
  }
}

// ── Flow card ─────────────────────────────────────────────────────────────────

class _FlowCard extends StatefulWidget {
  const _FlowCard({
    required this.flow,
    required this.index,
    required this.onToggle,
    required this.onEdit,
  });
  final Map<String, dynamic> flow;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  State<_FlowCard> createState() => _FlowCardState();
}

class _FlowCardState extends State<_FlowCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final f          = widget.flow;
    final name       = f['name'] as String? ?? '—';
    final desc       = f['description'] as String? ?? '';
    final isActive   = f['is_active'] as bool? ?? false;
    final rawFields  = f['fields'];
    final fields     = rawFields is List
        ? List<Map<String, dynamic>>.from(
            rawFields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    // Worker info
    final workerName  = f['worker_name'] as String?;
    final workerColor = f['worker_color'] as String?;
    final workerType  = f['worker_type'] as String? ?? f['catalog_worker_type'] as String? ?? 'custom';
    final typeEntry   = _kTypeConfig[workerType] ?? _kTypeConfig['custom']!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // ── Header row ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Number circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.ctTealLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctTealDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name + description + chips
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ctText,
                        ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          desc,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 12,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (fields.isNotEmpty)
                            _MetadataChip(label: '${fields.length} campo${fields.length == 1 ? '' : 's'}'),
                          if (workerName != null)
                            _WorkerChip(
                              name: workerName,
                              color: workerColor,
                            ),
                          _TypeBadge(typeEntry: typeEntry),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Badge + switch + edit button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.ctOkBg
                                : AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isActive ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? AppColors.ctOkText
                                  : AppColors.ctText2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: isActive,
                            onChanged: (_) => widget.onToggle(),
                            activeThumbColor: AppColors.ctTeal,
                            activeTrackColor:
                                AppColors.ctTeal.withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.ctBorder2,
                            inactiveTrackColor: AppColors.ctSurface2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _EditButton(onTap: widget.onEdit),
                  ],
                ),
              ],
            ),
          ),

          // ── Expand toggle ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.ctText2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expanded
                        ? 'Ocultar campos'
                        : 'Ver campos ${fields.length}',
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

          // ── Expandable fields table ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _FieldsTable(fields: fields),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Fields table ──────────────────────────────────────────────────────────────

class _FieldsTable extends StatelessWidget {
  const _FieldsTable({required this.fields});
  final List<Map<String, dynamic>> fields;

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
      decoration: const BoxDecoration(
        color: AppColors.ctBg,
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(9),
          bottomRight: Radius.circular(9),
        ),
      ),
      child: fields.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Sin campos configurados',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            )
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text('CAMPO', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('TIPO', style: _headerStyle)),
                      Expanded(flex: 1, child: Text('REQUERIDO', style: _headerStyle)),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.ctBorder),
                ...fields.asMap().entries.map((entry) {
                  final isLast = entry.key == fields.length - 1;
                  return Column(
                    children: [
                      _FieldRow(field: entry.value),
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

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});
  final Map<String, dynamic> field;

  @override
  Widget build(BuildContext context) {
    final label    = field['label'] as String? ?? field['name'] as String? ?? '—';
    final type     = field['type'] as String? ?? '—';
    final required = field['required'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ctSurface2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.ctBorder),
                ),
                child: Text(
                  type,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  required
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 13,
                  color: required ? AppColors.ctOk : AppColors.ctText3,
                ),
                const SizedBox(width: 4),
                Text(
                  required ? 'Sí' : 'No',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: required ? AppColors.ctOkText : AppColors.ctText3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Flow form dialog ──────────────────────────────────────────────────────────

class _FlowFormDialog extends StatefulWidget {
  const _FlowFormDialog({
    required this.workers,
    required this.onSaved,
    required this.tenantId,
    this.flow,
  });
  final Map<String, dynamic>? flow;
  final List<Map<String, dynamic>> workers;
  final Future<void> Function() onSaved;
  final String tenantId;

  @override
  State<_FlowFormDialog> createState() => _FlowFormDialogState();
}

class _FlowFormDialogState extends State<_FlowFormDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedWorkerId;
  bool _saving = false;

  bool get _isEdit => widget.flow != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _nameCtrl.text = widget.flow!['name'] as String? ?? '';
      _descCtrl.text = widget.flow!['description'] as String? ?? '';
    }
    if (widget.workers.isNotEmpty) {
      _selectedWorkerId = widget.workers.first['id'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);
    try {
      final desc = _descCtrl.text.trim();
      if (_isEdit) {
        await FlowsApi.updateFlow(
          flowId: widget.flow!['id'] as String,
          name: name,
          description: desc.isNotEmpty ? desc : null,
        );
      } else {
        if (_selectedWorkerId == null) return;
        await FlowsApi.createFlow(
          tenantId: widget.tenantId,
          tenantWorkerId: _selectedWorkerId!,
          name: name,
          description: desc.isNotEmpty ? desc : null,
        );
      }
      await widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final isDio = e is DioException;
      final is409 = isDio && e.response?.statusCode == 409;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: is409
            ? const Color(0xFFF97316)
            : AppColors.ctDanger,
        content: Text(
          is409
              ? 'Ya existe un flujo con ese nombre'
              : _dioError(e),
          style: const TextStyle(fontFamily: 'Geist', color: Colors.white),
        ),
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final editWorkerName = _isEdit
        ? (widget.flow!['worker_name'] as String? ??
            widget.flow!['display_name'] as String?)
        : null;

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Editar flujo' : 'Nuevo flujo',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              _DialogField(
                label: 'Nombre del flujo',
                controller: _nameCtrl,
                placeholder: 'Ej: Flujo 4 · Entregas',
              ),
              const SizedBox(height: 14),

              // Worker
              const Text(
                'Worker',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              if (_isEdit)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ctBorder2),
                  ),
                  child: Text(
                    editWorkerName ?? '—',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.ctText2,
                    ),
                  ),
                )
              else if (widget.workers.isEmpty)
                const Text(
                  'No hay workers disponibles',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText2,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ctBorder2),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedWorkerId,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: AppColors.ctSurface,
                    items: widget.workers.map((w) {
                      final wName  = w['display_name'] as String? ??
                          w['catalog_name'] as String? ?? '—';
                      final wColor = w['catalog_color'] as String?;
                      return DropdownMenuItem<String>(
                        value: w['id'] as String?,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _hexColor(wColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              wName,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 13,
                                color: AppColors.ctText,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedWorkerId = v),
                  ),
                ),
              const SizedBox(height: 14),

              // Descripción
              _DialogField(
                label: 'Descripción',
                controller: _descCtrl,
                placeholder: 'Describe el propósito de este flujo...',
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _PrimaryButton(
                    label: _saving ? 'Guardando...' : 'Guardar',
                    onTap: _saving ? () {} : _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          color: AppColors.ctText2,
        ),
      ),
    );
  }
}

class _WorkerChip extends StatelessWidget {
  const _WorkerChip({required this.name, this.color});
  final String name;
  final String? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _hexColor(color),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              color: AppColors.ctText2,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.typeEntry});
  final ({String label, Color bg, Color fg}) typeEntry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: typeEntry.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        typeEntry.label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: typeEntry.fg,
        ),
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctInfo.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hovered
                  ? AppColors.ctInfo.withValues(alpha: 0.4)
                  : AppColors.ctBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 13,
                color: _hovered ? AppColors.ctInfo : AppColors.ctText2,
              ),
              const SizedBox(width: 5),
              Text(
                'Editar',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? AppColors.ctInfo : AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          minLines: maxLines,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
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
              borderSide: const BorderSide(color: AppColors.ctTeal),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.ctTeal,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.ctNavy,
          ),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  const _GhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder2),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}
