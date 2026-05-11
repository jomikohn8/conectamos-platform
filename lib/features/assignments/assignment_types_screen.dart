import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/assignments_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/screen_header.dart';

// ── Color options ─────────────────────────────────────────────────────────────

const _kColorOptions = [
  '#59E0CC', // ctTeal
  '#F59E0B', // naranja
  '#8B5CF6', // púrpura
  '#EF4444', // rojo
  '#3B82F6', // azul
];

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}


// ── Screen ────────────────────────────────────────────────────────────────────

class AssignmentTypesScreen extends ConsumerStatefulWidget {
  const AssignmentTypesScreen({super.key});

  @override
  ConsumerState<AssignmentTypesScreen> createState() =>
      _AssignmentTypesScreenState();
}

class _AssignmentTypesScreenState
    extends ConsumerState<AssignmentTypesScreen> {
  List<Map<String, dynamic>> _types = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Drawer state
  Map<String, dynamic>? _editingType;
  final _labelCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  String _editScope = 'date';
  String _editColor = '#59E0CC';
  List<Map<String, dynamic>> _editFields = [];
  bool _editIsActive = true;

  // Toast
  String? _toast;
  Timer? _toastTimer;

  bool get _showDrawer => _editingType != null;
  bool get _isNewType =>
      _editingType != null &&
      (_editingType!['slug'] == null ||
          (_editingType!['slug'] as String).isEmpty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTypes());
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _slugCtrl.dispose();
    _toastTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTypes() async {
    final tenantId = ref.read(activeTenantIdProvider);
    setState(() => _isLoading = true);
    try {
      final types = await AssignmentsApi.getAssignmentTypes(tenantId: tenantId);
      if (!mounted) return;
      setState(() { _types = types; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast('Error al cargar tipos: $e');
    }
  }

  void _showToast(String msg) {
    setState(() => _toast = msg);
    _toastTimer?.cancel();
    _toastTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _toast = null);
    });
  }

  void _openNew() {
    setState(() {
      _editingType = <String, dynamic>{};
      _labelCtrl.text = '';
      _slugCtrl.text = '';
      _editScope = 'date';
      _editColor = '#59E0CC';
      _editFields = [];
      _editIsActive = true;
    });
  }

  void _openEdit(Map<String, dynamic> type) {
    setState(() {
      _editingType = type;
      _labelCtrl.text = type['label'] as String? ?? '';
      _slugCtrl.text = type['slug'] as String? ?? '';
      _editScope = type['scope'] as String? ?? 'date';
      _editColor = type['color'] as String? ?? '#59E0CC';
      final schema = type['data_schema'] ?? type['fields'];
      _editFields = (schema as List? ?? [])
          .map((f) => Map<String, dynamic>.from(f as Map))
          .toList();
      _editIsActive = type['is_active'] as bool? ?? true;
    });
  }

  void _closeDrawer() => setState(() => _editingType = null);

  void _addField() => setState(() {
        _editFields.add({'key': '', 'label': '', 'type': 'text'});
      });

  void _removeField(int idx) => setState(() => _editFields.removeAt(idx));

  Future<void> _save() async {
    final tenantId = ref.read(activeTenantIdProvider);
    final slug = _slugCtrl.text.trim();
    final label = _labelCtrl.text.trim();
    if (slug.isEmpty || label.isEmpty) return;
    final schema = _editFields
        .where((f) => (f['key'] as String? ?? '').isNotEmpty)
        .toList();
    setState(() => _isSaving = true);
    try {
      if (_isNewType) {
        await AssignmentsApi.createAssignmentType(
          tenantId: tenantId,
          body: {
            'slug': slug,
            'label': label,
            'scope': _editScope,
            'color': _editColor,
            'data_schema': schema,
          },
        );
        if (!mounted) return;
        setState(() { _isSaving = false; _editingType = null; });
        _showToast('Tipo creado');
      } else {
        await AssignmentsApi.updateAssignmentType(
          tenantId: tenantId,
          slug: _editingType!['slug'] as String,
          body: {
            'label': label,
            'scope': _editScope,
            'color': _editColor,
            'data_schema': schema,
            'is_active': _editIsActive,
          },
        );
        if (!mounted) return;
        setState(() { _isSaving = false; _editingType = null; });
        _showToast('Tipo actualizado');
      }
      await _loadTypes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showToast('Error: $e');
    }
  }

  Future<void> _delete() async {
    final tenantId = ref.read(activeTenantIdProvider);
    final slug = _editingType!['slug'] as String;
    setState(() => _isSaving = true);
    try {
      final result = await AssignmentsApi.deleteAssignmentType(
        tenantId: tenantId,
        slug: slug,
      );
      if (!mounted) return;
      setState(() { _isSaving = false; _editingType = null; });
      if (result['deactivated'] == true) {
        _showToast('Tipo desactivado — tiene asignaciones existentes');
      } else {
        _showToast('Tipo eliminado');
      }
      await _loadTypes();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showToast('Error: $e');
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> type, bool value) async {
    final tenantId = ref.read(activeTenantIdProvider);
    final slug = type['slug'] as String;
    try {
      await AssignmentsApi.updateAssignmentType(
        tenantId: tenantId,
        slug: slug,
        body: {'is_active': value},
      );
      await _loadTypes();
    } catch (e) {
      _showToast('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ctBg,
      body: Stack(
        children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                title: 'Tipos de asignación',
                subtitle:
                    'Define qué tipos de asignación maneja el tenant y su schema de datos.',
                actions: [
                  GestureDetector(
                    onTap: () => context.go('/assignments'),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_back_rounded,
                              size: 14, color: AppColors.ctText2),
                          const SizedBox(width: 4),
                          Text(
                            'Asignaciones',
                            style: AppFonts.geist(
                                fontSize: 13, color: AppColors.ctText2),
                          ),
                          Text(
                            ' / Tipos',
                            style: AppFonts.geist(
                                fontSize: 13, color: AppColors.ctText3),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _PrimaryButton(label: '+ Nuevo tipo', onTap: _openNew),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.ctTeal),
                        )
                      : _types.isEmpty
                          ? _EmptyState(onNew: _openNew)
                          : _TypesTable(
                              types: _types,
                              onEdit: _openEdit,
                              onToggleActive: _toggleActive,
                            ),
                ),
              ),
            ],
          ),
          // Backdrop
          if (_showDrawer)
            GestureDetector(
              onTap: _closeDrawer,
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
              ),
            ),
          // Sliding drawer
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            right: _showDrawer ? 0 : -520,
            top: 0,
            bottom: 0,
            width: 480,
            child: _buildDrawer(),
          ),
          // Toast
          if (_toast != null)
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.ctText,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _toast!,
                    style: AppFonts.geist(
                        fontSize: 13,
                        color: AppColors.ctSurface,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(left: BorderSide(color: AppColors.ctBorder)),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 24,
            offset: Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: AppColors.ctBorder)),
            ),
            child: Row(
              children: [
                Text(
                  _isNewType
                      ? 'Nuevo tipo'
                      : 'Editar: ${_editingType?['label'] ?? ''}',
                  style: AppFonts.onest(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _closeDrawer,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: AppColors.ctText2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable form body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel('Label'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _labelCtrl,
                    decoration: const InputDecoration(
                        hintText: 'Ej. CRUM diario'),
                    style: AppFonts.geist(
                        fontSize: 13, color: AppColors.ctText),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Slug'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _slugCtrl,
                    readOnly: !_isNewType,
                    decoration: InputDecoration(
                      hintText: 'Ej. crum_daily',
                      filled: true,
                      fillColor: !_isNewType
                          ? AppColors.ctSurface2
                          : AppColors.ctSurface,
                    ),
                    style: AppFonts.geist(
                        fontSize: 13, color: AppColors.ctText),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Scope'),
                  const SizedBox(height: 6),
                  _ScopeDropdown(
                    value: _editScope,
                    onChanged: (v) =>
                        setState(() => _editScope = v ?? 'date'),
                  ),
                  const SizedBox(height: 16),
                  const _FieldLabel('Color'),
                  const SizedBox(height: 8),
                  Row(
                    children: _kColorOptions.map((hex) {
                      final selected = hex == _editColor;
                      return GestureDetector(
                        onTap: () => setState(() => _editColor = hex),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _hexColor(hex),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: selected
                                    ? AppColors.ctText
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: selected
                                  ? const [
                                      BoxShadow(
                                        color:
                                            Color.fromRGBO(0, 0, 0, 0.15),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  const _FieldLabel('Schema de datos'),
                  const SizedBox(height: 8),
                  _FieldsTable(
                    fields: _editFields,
                    onChanged: (idx, field) =>
                        setState(() => _editFields[idx] = field),
                    onRemove: _removeField,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _addField,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded,
                              size: 14, color: AppColors.ctTeal),
                          const SizedBox(width: 4),
                          Text(
                            '+ Agregar campo',
                            style: AppFonts.geist(
                                fontSize: 12,
                                color: AppColors.ctTeal,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const _FieldLabel('Activo'),
                            const SizedBox(height: 2),
                            Text(
                              'Habilita o deshabilita este tipo de asignación.',
                              style: AppFonts.geist(
                                  fontSize: 11,
                                  color: AppColors.ctText2),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _editIsActive,
                        onChanged: (v) =>
                            setState(() => _editIsActive = v),
                        activeThumbColor: AppColors.ctTeal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Footer buttons
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.ctBorder)),
            ),
            child: Row(
              children: [
                if (!_isNewType)
                  _DeleteButton(
                    onTap: _isSaving ? null : _delete,
                  ),
                const Spacer(),
                _SecondaryButton(
                    label: 'Cancelar', onTap: _isSaving ? () {} : _closeDrawer),
                const SizedBox(width: 8),
                _PrimaryButton(
                    label: _isSaving ? 'Guardando…' : 'Guardar',
                    onTap: _isSaving ? () {} : _save),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Types table ───────────────────────────────────────────────────────────────

class _TypesTable extends StatelessWidget {
  const _TypesTable({
    required this.types,
    required this.onEdit,
    required this.onToggleActive,
  });

  final List<Map<String, dynamic>> types;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>, bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: AppColors.ctBorder)),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: const Row(
              children: [
                _ColHeader('Tipo', flex: 2),
                _ColHeader('Label', flex: 2),
                _ColHeader('Scope', flex: 1),
                _ColHeader('Color', flex: 1),
                _ColHeader('Schema', flex: 2),
                _ColHeader('Activo', flex: 1),
                _ColHeader('Acciones', flex: 1),
              ],
            ),
          ),
          // Data rows
          ...types.map((t) => _TypeRow(
                type: t,
                onEdit: onEdit,
                onToggleActive: onToggleActive,
              )),
        ],
      ),
    );
  }
}

class _ColHeader extends StatelessWidget {
  const _ColHeader(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppFonts.geist(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText3),
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.type,
    required this.onEdit,
    required this.onToggleActive,
  });

  final Map<String, dynamic> type;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>, bool) onToggleActive;

  @override
  Widget build(BuildContext context) {
    final schema = type['data_schema'] ?? type['fields'];
    final fields = (schema as List?) ?? [];
    final colorHex = type['color'] as String? ?? '#9CA3AF';
    final scope = type['scope'] as String? ?? 'date';
    final isActive = type['is_active'] as bool? ?? true;

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          // Tipo (slug chip)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.ctSurface2,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                type['slug'] as String? ?? '',
                style: AppFonts.geist(
                    fontSize: 11, color: AppColors.ctText2),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // Label (no dot)
          Expanded(
            flex: 2,
            child: Text(
              type['label'] as String? ?? '',
              style: AppFonts.geist(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Scope badge
          Expanded(flex: 1, child: _ScopeBadge(scope)),
          // Color dot
          Expanded(
            flex: 1,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: _hexColor(colorHex),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Schema count
          Expanded(
            flex: 2,
            child: Text(
              fields.isEmpty
                  ? '—'
                  : '${fields.length} campo${fields.length == 1 ? '' : 's'}',
              style: AppFonts.geist(
                  fontSize: 12, color: AppColors.ctText2),
            ),
          ),
          // Activo toggle
          Expanded(
            flex: 1,
            child: Transform.scale(
              scale: 0.75,
              alignment: Alignment.centerLeft,
              child: Switch(
                value: isActive,
                onChanged: (v) => onToggleActive(type, v),
                activeThumbColor: AppColors.ctTeal,
                activeTrackColor: AppColors.ctTeal.withValues(alpha: 0.3),
              ),
            ),
          ),
          // Edit action
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => onEdit(type),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    'Editar',
                    style: AppFonts.geist(
                        fontSize: 12,
                        color: AppColors.ctTeal,
                        fontWeight: FontWeight.w600),
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

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onNew});

  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 40, color: AppColors.ctText3),
          const SizedBox(height: 12),
          Text(
            'Sin tipos configurados',
            style: AppFonts.onest(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText),
          ),
          const SizedBox(height: 6),
          Text(
            'Crea el primer tipo de asignación para tu tenant.',
            style:
                AppFonts.geist(fontSize: 13, color: AppColors.ctText2),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(label: '+ Nuevo tipo', onTap: onNew),
        ],
      ),
    );
  }
}

// ── Fields schema table ───────────────────────────────────────────────────────

class _FieldsTable extends StatelessWidget {
  const _FieldsTable({
    required this.fields,
    required this.onChanged,
    required this.onRemove,
  });

  final List<Map<String, dynamic>> fields;
  final void Function(int idx, Map<String, dynamic> field) onChanged;
  final void Function(int idx) onRemove;

  @override
  Widget build(BuildContext context) {
    if (fields.isEmpty) {
      return Text(
        'Sin campos. Agrega al menos uno.',
        style: AppFonts.geist(fontSize: 12, color: AppColors.ctText3),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(7)),
              border: Border(
                  bottom: BorderSide(color: AppColors.ctBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text('Key',
                      style: AppFonts.geist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText3)),
                ),
                Expanded(
                  flex: 3,
                  child: Text('Label',
                      style: AppFonts.geist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText3)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Tipo',
                      style: AppFonts.geist(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText3)),
                ),
                const SizedBox(width: 28),
              ],
            ),
          ),
          // Rows
          ...fields.asMap().entries.map((entry) {
            final idx = entry.key;
            final f = entry.value;
            final isLast = idx == fields.length - 1;
            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: f['key'] as String? ?? '',
                      onChanged: (v) =>
                          onChanged(idx, {...f, 'key': v}),
                      decoration: const InputDecoration(
                        hintText: 'key',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                      style: AppFonts.geist(
                          fontSize: 12, color: AppColors.ctText),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      initialValue: f['label'] as String? ?? '',
                      onChanged: (v) =>
                          onChanged(idx, {...f, 'label': v}),
                      decoration: const InputDecoration(
                        hintText: 'Label',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                      style: AppFonts.geist(
                          fontSize: 12, color: AppColors.ctText),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: f['type'] as String? ?? 'text',
                      onChanged: (v) =>
                          onChanged(idx, {...f, 'type': v}),
                      decoration: const InputDecoration(
                        hintText: 'text',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                      ),
                      style: AppFonts.geist(
                          fontSize: 12, color: AppColors.ctText),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => onRemove(idx),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: const Icon(Icons.close_rounded,
                          size: 16, color: AppColors.ctText3),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Scope dropdown ────────────────────────────────────────────────────────────

class _ScopeDropdown extends StatelessWidget {
  const _ScopeDropdown(
      {required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String?> onChanged;

  static const _items = {
    'date': 'date — Un día completo',
    'window': 'window — Rango horario',
    'open': 'open — Sin scope',
  };

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: const InputDecoration(),
      items: _items.entries
          .map((e) =>
              DropdownMenuItem(value: e.key, child: Text(e.value)))
          .toList(),
      onChanged: onChanged,
      style: AppFonts.geist(fontSize: 13, color: AppColors.ctText),
    );
  }
}

// ── Scope badge ───────────────────────────────────────────────────────────────

class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge(this.scope);

  final String scope;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        scope,
        style: AppFonts.geist(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText2),
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.geist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.ctDanger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppColors.ctDanger.withValues(alpha: 0.4)),
          ),
          child: Text(
            'Eliminar',
            style: AppFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ctDanger),
          ),
        ),
      ),
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ctNavy),
          ),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.ctSurface,
            border: Border.all(color: AppColors.ctBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: AppFonts.geist(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText),
          ),
        ),
      ),
    );
  }
}
