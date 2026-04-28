import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/flows_api.dart';
import '../../core/providers/permissions_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _hexColor(String? hex) {
  try {
    final h = (hex ?? '#9CA3AF').replaceAll('#', '');
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

IconData _fieldIcon(String? type) {
  switch (type) {
    case 'number':
      return Icons.pin_outlined;
    case 'date':
      return Icons.calendar_today_outlined;
    case 'boolean':
      return Icons.toggle_on_outlined;
    case 'select':
      return Icons.list_outlined;
    case 'photo':
      return Icons.photo_camera_outlined;
    case 'location':
      return Icons.location_on_outlined;
    default:
      return Icons.short_text;
  }
}

const _kFieldTypes = [
  ('text', 'Texto'),
  ('number', 'Número'),
  ('date', 'Fecha'),
  ('boolean', 'Sí / No'),
  ('select', 'Selección'),
  ('photo', 'Foto'),
  ('location', 'Ubicación'),
];

const _kTriggerSources = [
  ('conversational', 'Conversacional'),
  ('api', 'API / Sistema'),
  ('dashboard', 'Dashboard'),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class FlowDetailScreen extends ConsumerStatefulWidget {
  const FlowDetailScreen({super.key, required this.flowId});
  final String flowId;

  @override
  ConsumerState<FlowDetailScreen> createState() => _FlowDetailScreenState();
}

class _FlowDetailScreenState extends ConsumerState<FlowDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _flow;
  bool _loading = true;
  String? _error;
  bool _saving = false;

  late TabController _tabCtrl;

  // Info tab controllers — initialized in _load()
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  List<String> _triggerSources = [];

  // Campos tab state
  List<Map<String, dynamic>> _fields = [];

  // Comportamiento tab state
  List<Map<String, dynamic>> _conditions = [];

  // Al cerrar tab state
  List<Map<String, dynamic>> _actions = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _slugCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading && _flow != null) return;
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final flow = await FlowsApi.getFlow(
        tenantId: tenantId,
        flowId: widget.flowId,
      );
      if (!mounted) return;
      final rawFields = flow['fields'];
      final fields = rawFields is List
          ? List<Map<String, dynamic>>.from(
              rawFields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
          : <Map<String, dynamic>>[];
      final rawSources = flow['trigger_sources'];
      final sources = rawSources is List
          ? List<String>.from(rawSources.map((s) => s.toString()))
          : <String>[];

      final rawBehavior = (flow['behavior'] as Map<String, dynamic>?) ?? {};
      final conditions = List<Map<String, dynamic>>.from(
          (rawBehavior['conditions'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)));
      final rawOnComplete =
          (flow['on_complete'] as Map<String, dynamic>?) ?? {};
      final actions = List<Map<String, dynamic>>.from(
          (rawOnComplete['actions'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)));

      setState(() {
        _flow = flow;
        _fields = fields;
        _triggerSources = sources;
        _conditions = conditions;
        _actions = actions;
        _nameCtrl.text = flow['name'] as String? ?? '';
        _slugCtrl.text = flow['slug'] as String? ?? '';
        _descCtrl.text = flow['description'] as String? ?? '';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _dioError(e);
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = await FlowsApi.updateFlow(
        flowId: widget.flowId,
        name: _nameCtrl.text.trim(),
        slug: _slugCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        fields: _fields,
        behavior: {'conditions': _conditions},
        onComplete: {'actions': _actions},
        triggerSources: _triggerSources,
      );
      if (!mounted) return;
      final rawFields = updated['fields'];
      final fields = rawFields is List
          ? List<Map<String, dynamic>>.from(
              rawFields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
          : _fields;
      final rawBeh = (updated['behavior'] as Map<String, dynamic>?) ?? {};
      final updatedConditions = List<Map<String, dynamic>>.from(
          (rawBeh['conditions'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)));
      final rawOC = (updated['on_complete'] as Map<String, dynamic>?) ?? {};
      final updatedActions = List<Map<String, dynamic>>.from(
          (rawOC['actions'] as List? ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e)));
      setState(() {
        _flow = updated;
        _fields = fields;
        _conditions = updatedConditions;
        _actions = updatedActions;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Flujo guardado'),
        backgroundColor: AppColors.ctOk,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _fields.removeAt(oldIndex);
      _fields.insert(newIndex, item);
    });
  }

  void _openFieldDialog({Map<String, dynamic>? field, int? index}) {
    showDialog(
      context: context,
      builder: (_) => _FieldDialog(
        field: field,
        onSaved: (updated) {
          setState(() {
            if (index != null) {
              _fields[index] = updated;
            } else {
              _fields.add(updated);
            }
          });
        },
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _flow == null) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.ctDanger),
              const SizedBox(height: 12),
              Text(
                _error ?? 'No se encontró el flujo',
                style: const TextStyle(
                    fontFamily: 'Geist', color: AppColors.ctText2),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextButton(onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final canManage = hasPermission(ref, 'flows', 'manage');

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      appBar: _buildAppBar(),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _InfoTab(
            flow: _flow!,
            nameCtrl: _nameCtrl,
            slugCtrl: _slugCtrl,
            descCtrl: _descCtrl,
            triggerSources: _triggerSources,
            onTriggerToggle: (source) {
              setState(() {
                if (_triggerSources.contains(source)) {
                  if (_triggerSources.length > 1) {
                    _triggerSources.remove(source);
                  }
                } else {
                  _triggerSources.add(source);
                }
              });
            },
          ),
          _CamposTab(
            fields: _fields,
            canManage: canManage,
            onReorder: _onReorder,
            onEditField: (field, index) =>
                _openFieldDialog(field: field, index: index),
            onAddField: () => _openFieldDialog(),
          ),
          _ComportamientoTab(
            conditions: _conditions,
            flowFields: _fields,
            canManage: canManage,
            onChanged: (updated) => setState(() => _conditions = updated),
          ),
          _AlCerrarTab(
            actions: _actions,
            canManage: canManage,
            onChanged: (updated) => setState(() => _actions = updated),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final name = _flow?['name'] as String? ?? 'Flujo';
    return AppBar(
      backgroundColor: AppColors.ctNavy,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.go('/flows'),
      ),
      title: Text(
        name,
        style: AppFonts.onest(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      actions: [
        if (_flow != null && hasPermission(ref, 'flow_integrations', 'view'))
          IconButton(
            icon: const Icon(Icons.electrical_services_outlined, color: Colors.white70),
            tooltip: 'Integraciones',
            onPressed: () {
              final name = _flow!['name'] as String? ?? 'Flujo';
              context.go('/flows/${widget.flowId}/integrations?flowName=${Uri.encodeComponent(name)}');
            },
          ),
        if (_saving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          )
        else
          TextButton(
            onPressed: _loading ? null : _save,
            child: const Text(
              'Guardar',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ctTeal,
              ),
            ),
          ),
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.ctTeal,
        unselectedLabelColor: Colors.white60,
        indicatorColor: AppColors.ctTeal,
        labelStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Geist', fontSize: 12),
        tabs: const [
          Tab(text: 'INFO'),
          Tab(text: 'CAMPOS'),
          Tab(text: 'COMPORTAMIENTO'),
          Tab(text: 'AL CERRAR'),
        ],
      ),
    );
  }
}

// ── _InfoTab ──────────────────────────────────────────────────────────────────

class _InfoTab extends StatelessWidget {
  const _InfoTab({
    required this.flow,
    required this.nameCtrl,
    required this.slugCtrl,
    required this.descCtrl,
    required this.triggerSources,
    required this.onTriggerToggle,
  });

  final Map<String, dynamic> flow;
  final TextEditingController nameCtrl;
  final TextEditingController slugCtrl;
  final TextEditingController descCtrl;
  final List<String> triggerSources;
  final void Function(String source) onTriggerToggle;

  @override
  Widget build(BuildContext context) {
    final workerName = flow['worker_name'] as String?;
    final workerColor = flow['worker_color'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre
          _FormField(
            label: 'Nombre',
            controller: nameCtrl,
            placeholder: 'Ej: Flujo de entregas',
          ),
          const SizedBox(height: 16),

          // Slug
          _FormField(
            label: 'Slug',
            controller: slugCtrl,
            placeholder: 'ej: flujo-de-entregas',
            subtitle: 'Identificador único. Se usa en API e integraciones.',
          ),
          const SizedBox(height: 16),

          // Descripción
          _FormField(
            label: 'Descripción',
            controller: descCtrl,
            placeholder: 'Describe el propósito de este flujo...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Worker (read-only)
          if (workerName != null) ...[
            const Text(
              'Worker asignado',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.ctSurface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.ctBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _hexColor(workerColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    workerName,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Trigger sources
          const Text(
            '¿Desde dónde se puede iniciar este flujo?',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kTriggerSources.map((entry) {
              final (value, label) = entry;
              final selected = triggerSources.contains(value);
              return FilterChip(
                label: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.ctTealDark
                        : AppColors.ctText2,
                  ),
                ),
                selected: selected,
                onSelected: (_) => onTriggerToggle(value),
                selectedColor: AppColors.ctTealLight,
                backgroundColor: AppColors.ctSurface2,
                checkmarkColor: AppColors.ctTealDark,
                side: BorderSide(
                  color: selected
                      ? AppColors.ctTeal
                      : AppColors.ctBorder,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── _CamposTab ────────────────────────────────────────────────────────────────

class _CamposTab extends StatelessWidget {
  const _CamposTab({
    required this.fields,
    required this.canManage,
    required this.onReorder,
    required this.onEditField,
    required this.onAddField,
  });

  final List<Map<String, dynamic>> fields;
  final bool canManage;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(Map<String, dynamic> field, int index) onEditField;
  final VoidCallback onAddField;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Text(
                  'Campos del flujo (${fields.length})',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText,
                  ),
                ),
                const Spacer(),
                if (canManage)
                  TextButton.icon(
                    onPressed: onAddField,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text(
                      '+ Agregar campo',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.ctTeal,
                    ),
                  ),
              ],
            ),
          ),
        ),

        if (fields.isEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Sin campos configurados',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText2,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            sliver: SliverReorderableList(
              itemCount: fields.length,
              onReorder: canManage ? onReorder : (int a, int b) {},
              itemBuilder: (context, i) {
                final field = fields[i];
                final id = field['id']?.toString() ?? i.toString();
                return _FieldRow(
                  key: ValueKey(id),
                  field: field,
                  index: i,
                  canManage: canManage,
                  isLast: i == fields.length - 1,
                  onEdit: () => onEditField(field, i),
                );
              },
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }
}

// ── _FieldRow ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    super.key,
    required this.field,
    required this.index,
    required this.canManage,
    required this.isLast,
    required this.onEdit,
  });

  final Map<String, dynamic> field;
  final int index;
  final bool canManage;
  final bool isLast;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final label = field['label'] as String? ?? field['key'] as String? ?? '—';
    final type = field['type'] as String? ?? 'text';
    final required = field['required'] as bool? ?? false;

    final typeLabel = _kFieldTypes
        .where((e) => e.$1 == type)
        .map((e) => e.$2)
        .firstOrNull ?? type;

    return Container(
      color: AppColors.ctSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Row(
              children: [
                if (canManage)
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(
                      Icons.drag_handle_rounded,
                      size: 18,
                      color: AppColors.ctText3,
                    ),
                  )
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 10),
                Icon(
                  _fieldIcon(type),
                  size: 18,
                  color: AppColors.ctTeal,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText,
                        ),
                      ),
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          color: AppColors.ctText2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (required)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.ctTealLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Requerido',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctTealDark,
                      ),
                    ),
                  ),
                if (canManage) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.ctText2),
                    onPressed: onEdit,
                    tooltip: 'Editar campo',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                  ),
                ],
              ],
            ),
          ),
          if (!isLast)
            const Divider(height: 1, color: AppColors.ctBorder),
        ],
      ),
    );
  }
}

// ── _FieldDialog ──────────────────────────────────────────────────────────────

class _FieldDialog extends StatefulWidget {
  const _FieldDialog({
    required this.onSaved,
    this.field,
  });

  final Map<String, dynamic>? field;
  final void Function(Map<String, dynamic>) onSaved;

  @override
  State<_FieldDialog> createState() => _FieldDialogState();
}

class _FieldDialogState extends State<_FieldDialog> {
  final _labelCtrl = TextEditingController();
  String _type = 'text';
  bool _required = false;

  bool get _isEdit => widget.field != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _labelCtrl.text = widget.field!['label'] as String? ?? '';
      _type = widget.field!['type'] as String? ?? 'text';
      _required = widget.field!['required'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty) return;

    final updated = Map<String, dynamic>.from(widget.field ?? {});
    updated['label'] = label;
    updated['type'] = _type;
    updated['required'] = _required;
    if (!_isEdit || updated['id'] == null) {
      updated['id'] =
          DateTime.now().millisecondsSinceEpoch.toString();
    }

    widget.onSaved(updated);
    Navigator.pop(context);
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
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Editar campo' : 'Nuevo campo',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Label
              _FormField(
                label: 'Etiqueta',
                controller: _labelCtrl,
                placeholder: 'Ej: Número de guía',
              ),
              const SizedBox(height: 14),

              // Type
              const Text(
                'Tipo',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
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
                  value: _type,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.ctSurface,
                  items: _kFieldTypes.map((entry) {
                    final (value, label) = entry;
                    return DropdownMenuItem(
                      value: value,
                      child: Row(
                        children: [
                          Icon(_fieldIcon(value),
                              size: 16, color: AppColors.ctText2),
                          const SizedBox(width: 8),
                          Text(
                            label,
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
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Required toggle
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Requerido',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctText,
                      ),
                    ),
                  ),
                  Switch(
                    value: _required,
                    onChanged: (v) => setState(() => _required = v),
                    activeThumbColor: AppColors.ctTeal,
                    activeTrackColor:
                        AppColors.ctTeal.withValues(alpha: 0.3),
                  ),
                ],
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
                    label: 'Guardar',
                    onTap: _submit,
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

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.ctText3),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── _ComportamientoTab ────────────────────────────────────────────────────────

class _ComportamientoTab extends StatefulWidget {
  const _ComportamientoTab({
    required this.conditions,
    required this.flowFields,
    required this.canManage,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> conditions;
  final List<Map<String, dynamic>> flowFields;
  final bool canManage;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<_ComportamientoTab> createState() => _ComportamientoTabState();
}

class _ComportamientoTabState extends State<_ComportamientoTab> {
  late List<Map<String, dynamic>> _conditions;

  @override
  void initState() {
    super.initState();
    _conditions = List.from(widget.conditions);
  }

  @override
  void didUpdateWidget(_ComportamientoTab old) {
    super.didUpdateWidget(old);
    if (old.conditions != widget.conditions) {
      _conditions = List.from(widget.conditions);
    }
  }

  void _openConditionDialog(Map<String, dynamic>? condition) {
    showDialog(
      context: context,
      builder: (_) => _ConditionDialog(
        condition: condition,
        flowFields: widget.flowFields,
        onSaved: (updated) {
          setState(() {
            if (condition != null) {
              final idx = _conditions.indexWhere(
                  (c) => c['id'] == condition['id']);
              if (idx >= 0) {
                _conditions[idx] = updated;
              } else {
                _conditions.add(updated);
              }
            } else {
              _conditions.add(updated);
            }
          });
          widget.onChanged(List.from(_conditions));
        },
      ),
    );
  }

  void _deleteCondition(Map<String, dynamic> condition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ctSurface,
        title: const Text(
          'Eliminar condición',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ctText,
          ),
        ),
        content: const Text(
          '¿Eliminar esta condición de branching?',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText2,
          ),
        ),
        actions: [
          _GhostButton(
            label: 'Cancelar',
            onTap: () => Navigator.pop(ctx),
          ),
          const SizedBox(width: 8),
          _PrimaryButton(
            label: 'Eliminar',
            onTap: () {
              Navigator.pop(ctx);
              setState(() {
                _conditions.removeWhere((c) => c['id'] == condition['id']);
              });
              widget.onChanged(List.from(_conditions));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Condiciones de branching',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ctText,
                ),
              ),
              const Spacer(),
              if (widget.canManage)
                TextButton(
                  onPressed: () => _openConditionDialog(null),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.ctTeal),
                  child: const Text(
                    '+ Agregar condición',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_conditions.isEmpty)
            const SizedBox(
              height: 200,
              child: _EmptyState(
                icon: Icons.alt_route_outlined,
                message:
                    'Sin condiciones definidas.\nEste flujo avanza linealmente.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _conditions.length,
              separatorBuilder: (context2, i2) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ConditionCard(
                condition: _conditions[i],
                canManage: widget.canManage,
                onEdit: () => _openConditionDialog(_conditions[i]),
                onDelete: () => _deleteCondition(_conditions[i]),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── _ConditionCard ────────────────────────────────────────────────────────────

class _ConditionCard extends StatelessWidget {
  const _ConditionCard({
    required this.condition,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> condition;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final field = condition['field'] as String? ?? '';
    final operator = condition['operator'] as String? ?? '';
    final value = condition['value']?.toString() ?? '';
    final label = condition['label'] as String?;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder),
        // left accent
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                color: AppColors.ctTeal,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.ctTealLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            operator,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctTealDark,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$field $operator "$value"',
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (label != null && label.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          color: AppColors.ctText2,
                        ),
                      ),
                    ],
                    if (canManage) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                size: 16, color: AppColors.ctText2),
                            onPressed: onEdit,
                            tooltip: 'Editar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: AppColors.ctDanger),
                            onPressed: onDelete,
                            tooltip: 'Eliminar',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 30, minHeight: 30),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _ConditionDialog ──────────────────────────────────────────────────────────

const _kOperators = [
  ('==', 'igual a'),
  ('!=', 'distinto de'),
  ('<', 'menor que'),
  ('<=', 'menor o igual'),
  ('>', 'mayor que'),
  ('>=', 'mayor o igual'),
  ('in', 'contiene'),
  ('not in', 'no contiene'),
];

class _ConditionDialog extends StatefulWidget {
  const _ConditionDialog({
    required this.flowFields,
    required this.onSaved,
    this.condition,
  });

  final Map<String, dynamic>? condition;
  final List<Map<String, dynamic>> flowFields;
  final void Function(Map<String, dynamic>) onSaved;

  @override
  State<_ConditionDialog> createState() => _ConditionDialogState();
}

class _ConditionDialogState extends State<_ConditionDialog> {
  String? _selectedFieldId; // stored as "fields.{id}"
  String _operator = '==';
  final _valueCtrl = TextEditingController();
  final _labelCtrl = TextEditingController();

  bool get _isEdit => widget.condition != null;

  String? get _selectedFieldType {
    if (_selectedFieldId == null) return null;
    final rawId =
        _selectedFieldId!.startsWith('fields.')
            ? _selectedFieldId!.substring(7)
            : _selectedFieldId!;
    final match = widget.flowFields
        .where((f) => f['id']?.toString() == rawId)
        .firstOrNull;
    return match?['type'] as String?;
  }

  String get _valueHint {
    switch (_selectedFieldType) {
      case 'number':
        return 'ej. 100';
      case 'boolean':
        return 'true o false';
      case 'date':
        return 'ej. 2026-01-01';
      case 'select':
        return 'ej. opción_a';
      default:
        return 'ej. pendiente';
    }
  }

  @override
  void initState() {
    super.initState();
    final cond = widget.condition;
    if (cond != null) {
      _selectedFieldId = cond['field'] as String?;
      _operator = cond['operator'] as String? ?? '==';
      _valueCtrl.text = cond['value']?.toString() ?? '';
      _labelCtrl.text = cond['label'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _valueCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedFieldId == null) return;
    if (_valueCtrl.text.trim().isEmpty) return;

    final updated = Map<String, dynamic>.from(widget.condition ?? {});
    updated['field'] = _selectedFieldId;
    updated['operator'] = _operator;
    updated['value'] = _valueCtrl.text.trim();
    final lbl = _labelCtrl.text.trim();
    if (lbl.isNotEmpty) updated['label'] = lbl;
    if (!_isEdit || updated['id'] == null) {
      updated['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }

    widget.onSaved(updated);
    Navigator.pop(context);
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Condición' : 'Nueva condición',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Campo
              const Text(
                'Campo',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              _DropdownContainer(
                child: DropdownButton<String>(
                  value: _selectedFieldId,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  hint: const Text(
                    'Selecciona un campo',
                    style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctText3),
                  ),
                  dropdownColor: AppColors.ctSurface,
                  items: widget.flowFields.map((f) {
                    final id = f['id']?.toString() ?? '';
                    final lbl = f['label'] as String? ?? id;
                    return DropdownMenuItem(
                      value: 'fields.$id',
                      child: Text(
                        lbl,
                        style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: AppColors.ctText),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedFieldId = v),
                ),
              ),
              const SizedBox(height: 14),

              // Operador
              const Text(
                'Operador',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              _DropdownContainer(
                child: DropdownButton<String>(
                  value: _operator,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.ctSurface,
                  items: _kOperators.map((entry) {
                    final (val, lbl) = entry;
                    return DropdownMenuItem(
                      value: val,
                      child: Text(
                        '$val — $lbl',
                        style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: AppColors.ctText),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _operator = v);
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Valor
              _FormField(
                label: 'Valor',
                controller: _valueCtrl,
                placeholder: _valueHint,
              ),
              const SizedBox(height: 14),

              // Etiqueta
              _FormField(
                label: 'Etiqueta (opcional)',
                controller: _labelCtrl,
                placeholder: 'Descripción legible (opcional)',
              ),

              // Preview
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: _valueCtrl,
                builder: (context2, value, child) {
                  if (_selectedFieldId == null || _valueCtrl.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    'Expresión: $_selectedFieldId $_operator "${_valueCtrl.text}"',
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      color: AppColors.ctText2,
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                      label: 'Cancelar',
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  _PrimaryButton(label: 'Guardar', onTap: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _AlCerrarTab ──────────────────────────────────────────────────────────────

class _AlCerrarTab extends StatefulWidget {
  const _AlCerrarTab({
    required this.actions,
    required this.canManage,
    required this.onChanged,
  });

  final List<Map<String, dynamic>> actions;
  final bool canManage;
  final ValueChanged<List<Map<String, dynamic>>> onChanged;

  @override
  State<_AlCerrarTab> createState() => _AlCerrarTabState();
}

class _AlCerrarTabState extends State<_AlCerrarTab> {
  late List<Map<String, dynamic>> _actions;

  @override
  void initState() {
    super.initState();
    _actions = List.from(widget.actions);
  }

  @override
  void didUpdateWidget(_AlCerrarTab old) {
    super.didUpdateWidget(old);
    if (old.actions != widget.actions) {
      _actions = List.from(widget.actions);
    }
  }

  void _openActionDialog(Map<String, dynamic>? action) {
    showDialog(
      context: context,
      builder: (_) => _ActionDialog(
        action: action,
        onSaved: (updated) {
          setState(() {
            if (action != null) {
              final idx =
                  _actions.indexWhere((a) => a['id'] == action['id']);
              if (idx >= 0) {
                _actions[idx] = updated;
              } else {
                _actions.add(updated);
              }
            } else {
              _actions.add(updated);
            }
          });
          widget.onChanged(List.from(_actions));
        },
      ),
    );
  }

  void _deleteAction(Map<String, dynamic> action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.ctSurface,
        title: const Text(
          'Eliminar acción',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ctText,
          ),
        ),
        content: const Text(
          '¿Eliminar esta acción?',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText2,
          ),
        ),
        actions: [
          _GhostButton(
              label: 'Cancelar', onTap: () => Navigator.pop(ctx)),
          const SizedBox(width: 8),
          _PrimaryButton(
            label: 'Eliminar',
            onTap: () {
              Navigator.pop(ctx);
              setState(() {
                _actions.removeWhere((a) => a['id'] == action['id']);
              });
              widget.onChanged(List.from(_actions));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Acciones al completar el flujo',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ctText,
                ),
              ),
              const Spacer(),
              if (widget.canManage)
                TextButton(
                  onPressed: () => _openActionDialog(null),
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.ctTeal),
                  child: const Text(
                    '+ Agregar acción',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Se ejecutan en orden cuando el flujo se marca como completado.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: AppColors.ctText2,
            ),
          ),
          const SizedBox(height: 16),
          if (_actions.isEmpty)
            const SizedBox(
              height: 200,
              child: _EmptyState(
                icon: Icons.check_circle_outline,
                message:
                    'Sin acciones configuradas.\nEl flujo cierra sin efectos secundarios.',
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _actions.length,
              separatorBuilder: (context2, i2) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _ActionCard(
                action: _actions[i],
                canManage: widget.canManage,
                onEdit: () => _openActionDialog(_actions[i]),
                onDelete: () => _deleteAction(_actions[i]),
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── _ActionCard ───────────────────────────────────────────────────────────────

IconData _actionIcon(String? type) {
  switch (type) {
    case 'webhook_out':
      return Icons.webhook_outlined;
    case 'emit_event':
      return Icons.notifications_outlined;
    default:
      return Icons.account_tree_outlined;
  }
}

String _actionLabel(String? type) {
  switch (type) {
    case 'webhook_out':
      return 'Webhook saliente';
    case 'emit_event':
      return 'Emitir evento';
    default:
      return 'Abrir flujo';
  }
}

String _actionSubtitle(Map<String, dynamic> action) {
  final type = action['type'] as String?;
  switch (type) {
    case 'open_flow':
      final slug = action['target_flow_slug'] as String? ?? '';
      return '→ $slug';
    case 'webhook_out':
      final id = action['integration_id'] as String? ?? '';
      final short = id.length > 8 ? id.substring(0, 8) : id;
      return '↗ $short';
    case 'emit_event':
      final name = action['event_name'] as String? ?? '';
      return '⚡ $name';
    default:
      return '';
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> action;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final type = action['type'] as String?;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(_actionIcon(type), size: 20, color: AppColors.ctTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actionLabel(type),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText,
                  ),
                ),
                Text(
                  _actionSubtitle(action),
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          if (canManage) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  size: 16, color: AppColors.ctText2),
              onPressed: onEdit,
              tooltip: 'Editar',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  size: 16, color: AppColors.ctDanger),
              onPressed: onDelete,
              tooltip: 'Eliminar',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 30, minHeight: 30),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _ActionDialog ─────────────────────────────────────────────────────────────

class _ActionDialog extends StatefulWidget {
  const _ActionDialog({required this.onSaved, this.action});

  final Map<String, dynamic>? action;
  final void Function(Map<String, dynamic>) onSaved;

  @override
  State<_ActionDialog> createState() => _ActionDialogState();
}

class _ActionDialogState extends State<_ActionDialog> {
  String _type = 'open_flow';

  // open_flow
  final _slugCtrl = TextEditingController();
  final _carryCtrl = TextEditingController();
  bool _carryAncestors = false;

  // webhook_out
  final _integrationCtrl = TextEditingController();
  bool _includeAncestors = false;

  // emit_event
  final _eventNameCtrl = TextEditingController();

  bool get _isEdit => widget.action != null;

  @override
  void initState() {
    super.initState();
    final a = widget.action;
    if (a != null) {
      _type = a['type'] as String? ?? 'open_flow';
      _slugCtrl.text = a['target_flow_slug'] as String? ?? '';
      final cf = a['carry_fields'];
      _carryCtrl.text =
          cf is List ? cf.map((e) => e.toString()).join(', ') : '';
      _carryAncestors = a['carry_ancestors'] as bool? ?? false;
      _integrationCtrl.text = a['integration_id'] as String? ?? '';
      _includeAncestors = a['include_ancestors'] as bool? ?? false;
      _eventNameCtrl.text = a['event_name'] as String? ?? '';
    }
  }

  @override
  void dispose() {
    _slugCtrl.dispose();
    _carryCtrl.dispose();
    _integrationCtrl.dispose();
    _eventNameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final updated = Map<String, dynamic>.from(widget.action ?? {});
    updated['type'] = _type;
    if (!_isEdit || updated['id'] == null) {
      updated['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    switch (_type) {
      case 'open_flow':
        if (_slugCtrl.text.trim().isEmpty) return;
        updated['target_flow_slug'] = _slugCtrl.text.trim();
        final raw = _carryCtrl.text.trim();
        if (raw.isNotEmpty) {
          updated['carry_fields'] =
              raw.split(',').map((s) => s.trim()).toList();
        } else {
          updated.remove('carry_fields');
        }
        updated['carry_ancestors'] = _carryAncestors;
        updated.remove('integration_id');
        updated.remove('include_ancestors');
        updated.remove('event_name');
        updated.remove('event_data');
        break;
      case 'webhook_out':
        if (_integrationCtrl.text.trim().isEmpty) return;
        updated['integration_id'] = _integrationCtrl.text.trim();
        updated['include_ancestors'] = _includeAncestors;
        updated.remove('target_flow_slug');
        updated.remove('carry_fields');
        updated.remove('carry_ancestors');
        updated.remove('event_name');
        updated.remove('event_data');
        break;
      case 'emit_event':
        if (_eventNameCtrl.text.trim().isEmpty) return;
        updated['event_name'] = _eventNameCtrl.text.trim();
        updated.remove('target_flow_slug');
        updated.remove('carry_fields');
        updated.remove('carry_ancestors');
        updated.remove('integration_id');
        updated.remove('include_ancestors');
        break;
    }
    widget.onSaved(updated);
    Navigator.pop(context);
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEdit ? 'Acción' : 'Nueva acción',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Tipo
              const Text(
                'Tipo de acción',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              _DropdownContainer(
                child: DropdownButton<String>(
                  value: _type,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.ctSurface,
                  items: const [
                    DropdownMenuItem(
                      value: 'open_flow',
                      child: Text('Abrir flujo',
                          style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctText)),
                    ),
                    DropdownMenuItem(
                      value: 'webhook_out',
                      child: Text('Webhook saliente',
                          style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctText)),
                    ),
                    DropdownMenuItem(
                      value: 'emit_event',
                      child: Text('Emitir evento',
                          style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctText)),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Campos condicionales
              if (_type == 'open_flow') ...[
                _FormField(
                  label: 'Slug del flujo destino',
                  controller: _slugCtrl,
                  placeholder: 'ej. asignar-operador',
                ),
                const SizedBox(height: 14),
                _FormField(
                  label: 'Campos a heredar',
                  controller: _carryCtrl,
                  placeholder: 'ej. orden_id, cliente — separados por coma',
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Heredar todos los ancestros',
                    style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctText),
                  ),
                  value: _carryAncestors,
                  onChanged: (v) => setState(() => _carryAncestors = v),
                  activeThumbColor: AppColors.ctTeal,
                  activeTrackColor: AppColors.ctTeal.withValues(alpha: 0.4),
                ),
              ] else if (_type == 'webhook_out') ...[
                _FormField(
                  label: 'ID de integración',
                  controller: _integrationCtrl,
                  placeholder: 'UUID de la flow_integration configurada',
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Incluir datos de ancestros',
                    style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctText),
                  ),
                  value: _includeAncestors,
                  onChanged: (v) => setState(() => _includeAncestors = v),
                  activeThumbColor: AppColors.ctTeal,
                  activeTrackColor: AppColors.ctTeal.withValues(alpha: 0.4),
                ),
              ] else if (_type == 'emit_event') ...[
                _FormField(
                  label: 'Nombre del evento',
                  controller: _eventNameCtrl,
                  placeholder: 'ej. flujo_completado',
                ),
              ],

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                      label: 'Cancelar',
                      onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 10),
                  _PrimaryButton(label: 'Guardar', onTap: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _DropdownContainer ────────────────────────────────────────────────────────

class _DropdownContainer extends StatelessWidget {
  const _DropdownContainer({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder2),
      ),
      child: child,
    );
  }
}

// ── Shared form widgets ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.subtitle,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String? subtitle;
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
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              color: AppColors.ctText3,
            ),
          ),
        ],
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
