import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api/catalogs_api.dart';
import '../../core/theme/app_theme.dart';

// ── Wizard principal ──────────────────────────────────────────────────────────

class NewCatalogWizard extends StatefulWidget {
  const NewCatalogWizard({
    super.key,
    required this.tenantId,
    required this.onSuccess,
  });
  final String tenantId;
  final void Function(String slug) onSuccess;

  @override
  State<NewCatalogWizard> createState() => _NewCatalogWizardState();
}

class _NewCatalogWizardState extends State<NewCatalogWizard> {
  int _step = 0;
  bool _saving = false;
  String? _error;

  // Step 0 — Tipo
  final _nameCtrl = TextEditingController();
  final _slugCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  bool _slugManuallyEdited = false;

  // Step 1 — Fuente
  String _sourceType = 'manual';
  final _sheetUrlCtrl  = TextEditingController();
  final _sheetNameCtrl = TextEditingController();
  final _fileIdCtrl    = TextEditingController();
  final _apiUrlCtrl    = TextEditingController();
  final _authHeaderCtrl = TextEditingController();

  // Step 2 — Schema
  final List<Map<String, dynamic>> _fields = [];
  String? _primaryKeyField;
  String? _displayField;
  int _uidCounter = 0;

  @override
  void initState() {
    super.initState();
    _sheetNameCtrl.text = 'Sheet1';
    _nameCtrl.addListener(_onNameChanged);
    _slugCtrl.addListener(_onSlugEdited);
  }

  @override
  void dispose() {
    _nameCtrl
      ..removeListener(_onNameChanged)
      ..dispose();
    _slugCtrl
      ..removeListener(_onSlugEdited)
      ..dispose();
    _descCtrl.dispose();
    _sheetUrlCtrl.dispose();
    _sheetNameCtrl.dispose();
    _fileIdCtrl.dispose();
    _apiUrlCtrl.dispose();
    _authHeaderCtrl.dispose();
    super.dispose();
  }

  // ── Slug auto-generation ────────────────────────────────────────────────────

  void _onNameChanged() {
    if (!_slugManuallyEdited) {
      final slug = _slugify(_nameCtrl.text);
      if (_slugCtrl.text != slug) {
        _slugCtrl.removeListener(_onSlugEdited);
        _slugCtrl.text = slug;
        _slugCtrl.addListener(_onSlugEdited);
      }
    }
    setState(() {});
  }

  void _onSlugEdited() {
    if (_slugCtrl.text != _slugify(_nameCtrl.text)) {
      _slugManuallyEdited = true;
    }
    setState(() {});
  }

  static String _slugify(String input) => input
      .toLowerCase()
      .replaceAll(' ', '_')
      .replaceAll(RegExp(r'[^a-z0-9_]'), '');

  // ── Validation ──────────────────────────────────────────────────────────────

  bool _canAdvance() {
    switch (_step) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty &&
            _slugCtrl.text.trim().isNotEmpty;
      case 1:
        return true;
      case 2:
        if (_fields.isEmpty) return false;
        if (_primaryKeyField == null || _displayField == null) return false;
        for (final f in _fields) {
          final k = f['key'] as String? ?? '';
          final l = f['label'] as String? ?? '';
          if (k.isEmpty || l.isEmpty) return false;
        }
        return true;
      default:
        return true;
    }
  }

  // ── Fields management ───────────────────────────────────────────────────────

  Map<String, dynamic> _newField() => {
        'key': '',
        'label': '',
        'type': 'text',
        'searchable': false,
        '_uid': (_uidCounter++).toString(),
      };

  // ── Source config builder ───────────────────────────────────────────────────

  Map<String, dynamic> _buildSourceConfig() {
    switch (_sourceType) {
      case 'google_sheets':
        return {
          'sheet_url': _sheetUrlCtrl.text.trim(),
          'sheet_name': _sheetNameCtrl.text.trim().isEmpty
              ? 'Sheet1'
              : _sheetNameCtrl.text.trim(),
        };
      case 'onedrive_excel':
        return {
          'file_id': _fileIdCtrl.text.trim(),
          'sheet_name': _sheetNameCtrl.text.trim().isEmpty
              ? 'Sheet1'
              : _sheetNameCtrl.text.trim(),
        };
      case 'api_pull':
        return {
          'api_url': _apiUrlCtrl.text.trim(),
          if (_authHeaderCtrl.text.trim().isNotEmpty)
            'auth_header': _authHeaderCtrl.text.trim(),
        };
      default:
        return {};
    }
  }

  // ── Submit ──────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() { _saving = true; _error = null; });
    try {
      final fieldsSchema = _fields
          .map((f) => {
                'key': f['key'],
                'label': f['label'],
                'type': f['type'],
                'searchable': f['searchable'],
                'is_primary': f['key'] == _primaryKeyField,
              })
          .toList();

      final body = <String, dynamic>{
        'label': _nameCtrl.text.trim(),
        'slug': _slugCtrl.text.trim(),
        if (_descCtrl.text.trim().isNotEmpty)
          'description': _descCtrl.text.trim(),
        'source_type': _sourceType,
        'source_config': _buildSourceConfig(),
        'fields_schema': fieldsSchema,
        'primary_key_field': _primaryKeyField,
        'display_field': _displayField,
        'searchable_fields': _fields
            .where((f) => f['searchable'] == true)
            .map((f) => f['key'] as String)
            .toList(),
        'sync_strategy':
            _sourceType == 'manual' ? 'manual' : 'pull_periodic',
        if (_sourceType != 'manual') 'sync_interval_minutes': 60,
        'embed_threshold': 50,
      };

      await CatalogsApi.createCatalog(
          tenantId: widget.tenantId, body: body);

      if (mounted) widget.onSuccess(_slugCtrl.text.trim());
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _saving = false; });
        messenger.showSnackBar(SnackBar(
          content: Text('Error al crear catálogo: $e'),
          backgroundColor: AppColors.ctDanger,
          duration: const Duration(milliseconds: 3000),
        ));
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: SizedBox(
        width: 600,
        height: 680,
        child: Column(
          children: [
            _buildHeader(),
            _StepIndicator(step: _step),
            const Divider(height: 1, color: AppColors.ctBorder),
            Expanded(child: _buildStep()),
            const Divider(height: 1, color: AppColors.ctBorder),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
      child: Row(
        children: [
          Text(
            'Nuevo catálogo',
            style: AppFonts.onest(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppColors.ctText2),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return _buildStep3();
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step--),
              child: const Text('← Anterior'),
            ),
          const Spacer(),
          if (_step < 3)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctTeal,
                foregroundColor: AppColors.ctNavy,
                disabledBackgroundColor: AppColors.ctSurface2,
              ),
              onPressed: _canAdvance()
                  ? () => setState(() => _step++)
                  : null,
              child: Text(
                'Siguiente →',
                style: AppFonts.geist(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctTeal,
                foregroundColor: AppColors.ctNavy,
                disabledBackgroundColor: AppColors.ctSurface2,
              ),
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.ctNavy),
                    )
                  : Text(
                      'Crear catálogo',
                      style: AppFonts.geist(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
            ),
        ],
      ),
    );
  }

  // ── Step 0 — Tipo básico ──────────────────────────────────────────────────

  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WizardLabel('Nombre *'),
          const SizedBox(height: 6),
          _WizardTextField(
            controller: _nameCtrl,
            hint: 'Ej. Productos, Municipios, Tarifas…',
          ),
          const SizedBox(height: 16),
          _WizardLabel('Slug *'),
          const SizedBox(height: 6),
          _WizardTextField(
            controller: _slugCtrl,
            hint: 'ej. productos_mx',
            helperText: 'Solo letras minúsculas, números y guión bajo.',
            inputFormatters: [_SlugInputFormatter()],
          ),
          const SizedBox(height: 16),
          _WizardLabel('Descripción'),
          const SizedBox(height: 6),
          _WizardTextField(
            controller: _descCtrl,
            hint: 'Descripción opcional del catálogo',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ── Step 1 — Fuente ───────────────────────────────────────────────────────

  static const _sourceOptions = [
    ('manual',         'Manual',           Icons.edit_note_rounded),
    ('google_sheets',  'Google Sheets',    Icons.table_chart_outlined),
    ('onedrive_excel', 'Excel (OneDrive)', Icons.grid_on_outlined),
    ('webhook_push',   'Webhook Push',     Icons.webhook_outlined),
    ('api_pull',       'API REST',         Icons.cloud_download_outlined),
  ];

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WizardLabel('Tipo de fuente'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _sourceOptions.map((opt) {
              final (value, label, icon) = opt;
              final active = _sourceType == value;
              return _SourceChip(
                label: label,
                icon: icon,
                active: active,
                onTap: () => setState(() {
                  _sourceType = value;
                }),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _buildSourceConfigFields(),
        ],
      ),
    );
  }

  Widget _buildSourceConfigFields() {
    switch (_sourceType) {
      case 'google_sheets':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WizardLabel('URL del Google Sheet'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _sheetUrlCtrl,
              hint: 'https://docs.google.com/spreadsheets/d/…',
            ),
            const SizedBox(height: 12),
            _WizardLabel('Nombre de la hoja'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _sheetNameCtrl,
              hint: 'Sheet1',
            ),
            const SizedBox(height: 12),
            Text(
              'Requiere conexión Google activa en Conexiones.',
              style: AppFonts.geist(
                  fontSize: 12,
                  color: AppColors.ctText2)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        );

      case 'onedrive_excel':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WizardLabel('File ID de OneDrive'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _fileIdCtrl,
              hint: 'ID del archivo Excel en OneDrive',
            ),
            const SizedBox(height: 12),
            _WizardLabel('Nombre de la hoja'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _sheetNameCtrl,
              hint: 'Sheet1',
            ),
            const SizedBox(height: 12),
            Text(
              'Requiere conexión Microsoft activa en Conexiones.',
              style: AppFonts.geist(
                  fontSize: 12,
                  color: AppColors.ctText2)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        );

      case 'webhook_push':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'El catálogo recibirá actualizaciones via webhook entrante.',
              style: AppFonts.geist(
                  fontSize: 12, color: AppColors.ctText2),
            ),
            const SizedBox(height: 6),
            Text(
              'El endpoint se configurará después de crear el catálogo.',
              style: AppFonts.geist(
                  fontSize: 12, color: AppColors.ctText2),
            ),
          ],
        );

      case 'api_pull':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WizardLabel('URL del endpoint'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _apiUrlCtrl,
              hint: 'https://api.ejemplo.com/catalogo',
            ),
            const SizedBox(height: 12),
            _WizardLabel('Header de autenticación (opcional)'),
            const SizedBox(height: 6),
            _WizardTextField(
              controller: _authHeaderCtrl,
              hint: 'Bearer token123…',
            ),
          ],
        );

      default: // manual
        return Text(
          'Los items se cargarán manualmente o vía bulk import.',
          style: AppFonts.geist(fontSize: 12, color: AppColors.ctText2),
        );
    }
  }

  // ── Step 2 — Schema ───────────────────────────────────────────────────────

  Widget _buildStep2() {
    final fieldKeys = _fields
        .map((f) => f['key'] as String? ?? '')
        .where((k) => k.isNotEmpty)
        .toList();

    // Reset selectors if the pointed key no longer exists
    if (_primaryKeyField != null &&
        !fieldKeys.contains(_primaryKeyField)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _primaryKeyField = null));
    }
    if (_displayField != null && !fieldKeys.contains(_displayField)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => setState(() => _displayField = null));
    }

    return Column(
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                'Campos del catálogo',
                style: AppFonts.onest(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () =>
                    setState(() => _fields.add(_newField())),
                icon: const Icon(Icons.add_rounded, size: 15),
                label: const Text('Agregar campo'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ctTeal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
        ),

        // Fields list
        Expanded(
          child: _fields.isEmpty
              ? Center(
                  child: Text(
                    'Sin campos — agrega al menos uno.',
                    style: AppFonts.geist(
                        fontSize: 12, color: AppColors.ctText3),
                  ),
                )
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _fields.length,
                  separatorBuilder: (a, b) =>
                      const SizedBox(height: 6),
                  itemBuilder: (ctx, i) {
                    final field = _fields[i];
                    final uid = field['_uid'] as String? ?? i.toString();
                    return _FieldRow(
                      key: ValueKey(uid),
                      field: field,
                      onChange: (updated) =>
                          setState(() => _fields[i] = updated),
                      onDelete: () => setState(() {
                        _fields.removeAt(i);
                      }),
                    );
                  },
                ),
        ),

        // Primary key + display field selectors
        if (_fields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _KeyDropdown(
                    label: 'Campo clave (primary key) *',
                    value: _primaryKeyField,
                    keys: fieldKeys,
                    onChanged: (v) =>
                        setState(() => _primaryKeyField = v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KeyDropdown(
                    label: 'Campo de display *',
                    value: _displayField,
                    keys: fieldKeys,
                    onChanged: (v) =>
                        setState(() => _displayField = v),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ── Step 3 — Confirmar ────────────────────────────────────────────────────

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del catálogo',
            style: AppFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.ctSurface,
              border: Border.all(color: AppColors.ctBorder),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _SummaryRow('Nombre', _nameCtrl.text.trim()),
                _SummaryRow('Slug', _slugCtrl.text.trim()),
                _SummaryRow(
                  'Fuente',
                  _sourceOptions
                          .firstWhere(
                            (o) => o.$1 == _sourceType,
                            orElse: () => (_sourceType, _sourceType,
                                Icons.storage_rounded),
                          )
                          .$2,
                ),
                _SummaryRow(
                    'Campos', '${_fields.length} campos definidos'),
                _SummaryRow(
                    'Campo clave', _primaryKeyField ?? '—'),
                _SummaryRow(
                    'Campo display', _displayField ?? '—'),
                if (_descCtrl.text.trim().isNotEmpty)
                  _SummaryRow(
                      'Descripción', _descCtrl.text.trim(),
                      isLast: true),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: AppFonts.geist(
                  fontSize: 12, color: AppColors.ctDanger),
            ),
          ],
        ],
      ),
    );
  }
}

// ── _StepIndicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});
  final int step;

  static const _labels = ['Tipo', 'Fuente', 'Schema', 'Confirmar'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: List.generate(_labels.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final leftDone = (i ~/ 2) < step;
            return Expanded(
              child: Container(
                height: 2,
                color: leftDone ? AppColors.ctTeal : AppColors.ctBorder,
              ),
            );
          }
          final idx = i ~/ 2;
          final isDone = idx < step;
          final isActive = idx == step;
          return _StepCircle(
            number: idx + 1,
            label: _labels[idx],
            isDone: isDone,
            isActive: isActive,
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.number,
    required this.label,
    required this.isDone,
    required this.isActive,
  });
  final int number;
  final String label;
  final bool isDone;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colored = isDone || isActive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colored ? AppColors.ctTeal : AppColors.ctSurface2,
            border: Border.all(
              color: colored ? AppColors.ctTeal : AppColors.ctBorder,
            ),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color:
                          isActive ? Colors.white : AppColors.ctText2,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: colored ? AppColors.ctTeal : AppColors.ctText2,
          ),
        ),
      ],
    );
  }
}

// ── _FieldRow ─────────────────────────────────────────────────────────────────

class _FieldRow extends StatefulWidget {
  const _FieldRow({
    super.key,
    required this.field,
    required this.onChange,
    required this.onDelete,
  });
  final Map<String, dynamic> field;
  final ValueChanged<Map<String, dynamic>> onChange;
  final VoidCallback onDelete;

  @override
  State<_FieldRow> createState() => _FieldRowState();
}

class _FieldRowState extends State<_FieldRow> {
  late final TextEditingController _keyCtrl;
  late final TextEditingController _labelCtrl;
  late String _type;
  late bool _searchable;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(
        text: widget.field['key'] as String? ?? '');
    _labelCtrl = TextEditingController(
        text: widget.field['label'] as String? ?? '');
    _type = widget.field['type'] as String? ?? 'text';
    _searchable = widget.field['searchable'] as bool? ?? false;

    _keyCtrl.addListener(_notify);
    _labelCtrl.addListener(_notify);
  }

  @override
  void dispose() {
    _keyCtrl
      ..removeListener(_notify)
      ..dispose();
    _labelCtrl
      ..removeListener(_notify)
      ..dispose();
    super.dispose();
  }

  void _notify() {
    widget.onChange({
      ...widget.field,
      'key': _keyCtrl.text,
      'label': _labelCtrl.text,
      'type': _type,
      'searchable': _searchable,
    });
  }

  static const _typeOptions = ['text', 'number', 'boolean', 'date'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // key
          Expanded(
            flex: 2,
            child: _MiniTextField(
              controller: _keyCtrl,
              hint: 'key',
              inputFormatters: [_SlugInputFormatter()],
            ),
          ),
          const SizedBox(width: 6),
          // label
          Expanded(
            flex: 2,
            child: _MiniTextField(
              controller: _labelCtrl,
              hint: 'label',
            ),
          ),
          const SizedBox(width: 6),
          // type dropdown
          SizedBox(
            width: 90,
            height: 34,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: AppColors.ctSurface,
                border: Border.all(color: AppColors.ctBorder2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _type,
                  isDense: true,
                  isExpanded: true,
                  style: AppFonts.geist(
                      fontSize: 11, color: AppColors.ctText),
                  icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 13,
                      color: AppColors.ctText3),
                  items: _typeOptions
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _type = v);
                    _notify();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // searchable checkbox
          Tooltip(
            message: 'Buscable',
            child: Checkbox(
              value: _searchable,
              activeColor: AppColors.ctTeal,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (v) {
                setState(() => _searchable = v ?? false);
                _notify();
              },
            ),
          ),
          // delete
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 16, color: AppColors.ctText2),
            onPressed: widget.onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Eliminar campo',
          ),
        ],
      ),
    );
  }
}

// ── Shared sub-widgets ────────────────────────────────────────────────────────

class _WizardLabel extends StatelessWidget {
  const _WizardLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppFonts.geist(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText2),
    );
  }
}

class _WizardTextField extends StatelessWidget {
  const _WizardTextField({
    required this.controller,
    required this.hint,
    this.helperText,
    this.maxLines = 1,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String hint;
  final String? helperText;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      style: AppFonts.geist(fontSize: 13, color: AppColors.ctText),
      decoration: InputDecoration(
        hintText: hint,
        helperText: helperText,
        hintStyle:
            AppFonts.geist(fontSize: 13, color: AppColors.ctText3),
        helperStyle:
            AppFonts.geist(fontSize: 11, color: AppColors.ctText3),
        filled: true,
        fillColor: AppColors.ctSurface,
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
          borderSide:
              const BorderSide(color: AppColors.ctTeal, width: 1.5),
        ),
      ),
    );
  }
}

class _MiniTextField extends StatelessWidget {
  const _MiniTextField({
    required this.controller,
    required this.hint,
    this.inputFormatters,
  });
  final TextEditingController controller;
  final String hint;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: TextField(
        controller: controller,
        inputFormatters: inputFormatters,
        style: AppFonts.geist(fontSize: 12, color: AppColors.ctText),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppFonts.geist(fontSize: 12, color: AppColors.ctText3),
          filled: true,
          fillColor: AppColors.ctSurface,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.ctBorder2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.ctBorder2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
                color: AppColors.ctTeal, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color:
                active ? AppColors.ctTealLight : AppColors.ctSurface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  active ? AppColors.ctTeal : AppColors.ctBorder2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: active
                      ? AppColors.ctTealDark
                      : AppColors.ctText2),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppFonts.geist(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active
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

class _KeyDropdown extends StatelessWidget {
  const _KeyDropdown({
    required this.label,
    required this.value,
    required this.keys,
    required this.onChanged,
  });
  final String label;
  final String? value;
  final List<String> keys;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: AppFonts.geist(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.ctText2)),
        const SizedBox(height: 4),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.ctSurface,
            border: Border.all(color: AppColors.ctBorder2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: (value != null && keys.contains(value))
                  ? value
                  : null,
              hint: Text('Seleccionar',
                  style: AppFonts.geist(
                      fontSize: 12, color: AppColors.ctText3)),
              isDense: true,
              isExpanded: true,
              style:
                  AppFonts.geist(fontSize: 12, color: AppColors.ctText),
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 15, color: AppColors.ctText3),
              items: keys
                  .map((k) =>
                      DropdownMenuItem(value: k, child: Text(k)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.isLast = false});
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom:
                    BorderSide(color: AppColors.ctBorder, width: 0.5)),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: AppFonts.geist(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText2)),
          ),
          Expanded(
            child: Text(value,
                style:
                    AppFonts.geist(fontSize: 12, color: AppColors.ctText)),
          ),
        ],
      ),
    );
  }
}

// ── Input formatters ──────────────────────────────────────────────────────────

class _SlugInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final sanitized = newValue.text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}
