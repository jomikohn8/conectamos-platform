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

      setState(() {
        _flow = flow;
        _fields = fields;
        _triggerSources = sources;
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
        behavior: (_flow?['behavior'] as Map<String, dynamic>?) ?? {},
        triggerSources: _triggerSources,
      );
      if (!mounted) return;
      final rawFields = updated['fields'];
      final fields = rawFields is List
          ? List<Map<String, dynamic>>.from(
              rawFields.whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
          : _fields;
      setState(() {
        _flow = updated;
        _fields = fields;
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
          const _ComingSoonTab(),
          const _ComingSoonTab(),
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

// ── _ComingSoonTab ────────────────────────────────────────────────────────────

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Próximamente · Esta sección se habilitará en la siguiente entrega',
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          color: AppColors.ctText3,
        ),
        textAlign: TextAlign.center,
      ),
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
