import 'package:flutter/material.dart';

import '../../core/api/templates_api.dart';
import '../../core/theme/colors.dart';

// ── Tipos de encabezado ────────────────────────────────────────────────────────

enum _HeaderType { none, text, image, video, file }

// ── Dialog principal ───────────────────────────────────────────────────────────

class TemplateCreateDialog extends StatefulWidget {
  const TemplateCreateDialog({
    super.key,
    required this.channelId,
    required this.tenantId,
  });

  final String channelId;
  final String tenantId;

  @override
  State<TemplateCreateDialog> createState() => _TemplateCreateDialogState();
}

class _TemplateCreateDialogState extends State<TemplateCreateDialog> {
  final _nameCtrl        = TextEditingController();
  final _headerTextCtrl  = TextEditingController();
  final _headerUrlCtrl   = TextEditingController();
  final _bodyCtrl        = TextEditingController();
  final _footerCtrl      = TextEditingController();
  final _bodyFocus       = FocusNode();

  String      _category   = 'MARKETING';
  String      _language   = 'es';
  _HeaderType _headerType = _HeaderType.none;
  bool        _submitting = false;
  String?     _nameError;
  int         _varCount   = 0;

  static const _categories = [
    (value: 'MARKETING',      label: 'Marketing'),
    (value: 'UTILITY',        label: 'Utilidad'),
    (value: 'AUTHENTICATION', label: 'Autenticación'),
  ];

  static const _languages = [
    (value: 'es',    label: 'Español (es)'),
    (value: 'en',    label: 'Inglés (en)'),
    (value: 'en_US', label: 'Inglés US (en_US)'),
    (value: 'pt_BR', label: 'Portugués BR (pt_BR)'),
  ];

  static final _nameRe = RegExp(r'^[a-z0-9_]*$');

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_refresh);
    _headerTextCtrl.addListener(_refresh);
    _headerUrlCtrl.addListener(_refresh);
    _footerCtrl.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    _nameCtrl.dispose();
    _headerTextCtrl.dispose();
    _headerUrlCtrl.dispose();
    _bodyCtrl.dispose();
    _footerCtrl.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  // ── helpers ─────────────────────────────────────────────────────────────────

  void _insertVariable() {
    _varCount++;
    final txt = _bodyCtrl.text;
    final sel = _bodyCtrl.selection;
    final tag = '{{$_varCount}}';
    final pos = (sel.isValid && sel.baseOffset >= 0) ? sel.baseOffset : txt.length;
    final next = txt.substring(0, pos) + tag + txt.substring(pos);
    _bodyCtrl.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: pos + tag.length),
    );
    _bodyFocus.requestFocus();
  }

  List<Map<String, dynamic>> _buildVariables() {
    final re = RegExp(r'\{\{(\d+)\}\}');
    return re
        .allMatches(_bodyCtrl.text)
        .map((m) => {'index': int.parse(m.group(1)!), 'example': ''})
        .toList();
  }

  bool _nameValid(String v) => _nameRe.hasMatch(v);

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty || !_nameValid(name)) {
      setState(() => _nameError =
          'Solo letras minúsculas, números y guiones bajos.');
      return;
    }
    if (_bodyCtrl.text.trim().isEmpty) return;

    setState(() { _submitting = true; _nameError = null; });
    try {
      final headerTypeStr = switch (_headerType) {
        _HeaderType.none  => null,
        _HeaderType.text  => 'TEXT',
        _HeaderType.image => 'IMAGE',
        _HeaderType.video => 'VIDEO',
        _HeaderType.file  => 'DOCUMENT',
      };
      final headerText = _headerType == _HeaderType.text
          ? _headerTextCtrl.text.trim()
          : null;
      final headerUrl = (_headerType != _HeaderType.none &&
              _headerType != _HeaderType.text)
          ? _headerUrlCtrl.text.trim()
          : null;
      final footerText = _footerCtrl.text.trim();

      await TemplatesApi.createTemplate(
        tenantId:         widget.tenantId,
        name:             name,
        category:         _category,
        language:         _language,
        bodyText:         _bodyCtrl.text.trim(),
        variables:        _buildVariables(),
        channelId:        widget.channelId,
        headerType:       headerTypeStr,
        headerText:       headerText,
        headerExampleUrl: headerUrl,
        footerText:       footerText.isEmpty ? null : footerText,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear la plantilla: $e'),
            backgroundColor: AppColors.ctDanger,
          ),
        );
      }
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 860,
          height: 620,
          child: ColoredBox(
            color: AppColors.ctSurface,
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(width: 520, child: _buildForm()),
                      const VerticalDivider(
                          width: 1, thickness: 1, color: AppColors.ctBorder),
                      Expanded(child: _buildPreview()),
                    ],
                  ),
                ),
                _buildFooterBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── header bar ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AppColors.ctNavy,
      child: Row(
        children: [
          const Text(
            'Nueva plantilla',
            style: TextStyle(
              fontFamily: 'Onest',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── form panel ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1 ── Nombre
          _sectionLabel('Nombre de plantilla *'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: InputDecoration(
              hintText: 'nombre_en_snake_case',
              hintStyle: const TextStyle(
                  fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
              errorText: _nameError,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
            onChanged: (v) {
              if (_nameError != null) {
                setState(() =>
                    _nameError = (v.isEmpty || _nameValid(v)) ? null : 'Solo letras minúsculas, números y guiones bajos.');
              }
            },
          ),
          const SizedBox(height: 16),

          // 2 ── Categoría + Idioma (row)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Categoría *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.ctText),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c.value, child: Text(c.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _category = v);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('Idioma *'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _language,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        isDense: true,
                      ),
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.ctText),
                      items: _languages
                          .map((l) => DropdownMenuItem(
                              value: l.value, child: Text(l.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _language = v);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3 ── Encabezado (opcional)
          _sectionLabel('Encabezado · Opcional'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _HeaderType.values
                .map((t) => _HeaderChip(
                      label: _headerTypeLabel(t),
                      selected: _headerType == t,
                      onTap: () => setState(() {
                        _headerType = t;
                        _headerTextCtrl.clear();
                        _headerUrlCtrl.clear();
                      }),
                    ))
                .toList(),
          ),
          if (_headerType == _HeaderType.text) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _headerTextCtrl,
              maxLength: 60,
              decoration: InputDecoration(
                hintText: 'Texto del encabezado',
                hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style:
                  const TextStyle(fontFamily: 'Geist', fontSize: 13),
            ),
          ] else if (_headerType != _HeaderType.none) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _headerUrlCtrl,
              decoration: InputDecoration(
                hintText: 'URL de ejemplo (requerido por Meta)',
                hintStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText3),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              style:
                  const TextStyle(fontFamily: 'Geist', fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          // 4 ── Mensaje (body)
          _sectionLabel('Mensaje *'),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyCtrl,
            focusNode: _bodyFocus,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: 'Escribe el cuerpo del mensaje…',
              hintStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText3),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _insertVariable,
            icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
            label: const Text('Variable',
                style: TextStyle(fontFamily: 'Geist', fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.ctTeal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(height: 16),

          // 5 ── Pie de página (opcional)
          _sectionLabel('Pie de página · Opcional'),
          const SizedBox(height: 6),
          TextField(
            controller: _footerCtrl,
            maxLength: 60,
            decoration: InputDecoration(
              hintText: 'Texto del pie de página',
              hintStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText3),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── preview panel ────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    final headerTxt   = _headerType == _HeaderType.text ? _headerTextCtrl.text : null;
    final headerMedia = _headerType != _HeaderType.none && _headerType != _HeaderType.text;
    final body        = _bodyCtrl.text;
    final footer      = _footerCtrl.text;
    final now         = TimeOfDay.now();
    final time = '${now.hour.toString().padLeft(2, '0')}:'
        '${now.minute.toString().padLeft(2, '0')}';

    return Container(
      color: const Color(0xFFEBEBE9),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista previa',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText2,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Align(
              alignment: Alignment.topRight,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.waBubbleAi,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(2),
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header media placeholder
                      if (headerMedia)
                        Container(
                          height: 90,
                          decoration: BoxDecoration(
                            color: AppColors.ctSurface2,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(2),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _headerTypeIcon(_headerType),
                              size: 28,
                              color: AppColors.ctText3,
                            ),
                          ),
                        ),
                      // Header text
                      if (headerTxt != null && headerTxt.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                          child: Text(
                            headerTxt,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctText,
                            ),
                          ),
                        ),
                      // Body
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            12,
                            (headerTxt != null && headerTxt.isNotEmpty) ||
                                    headerMedia
                                ? 6
                                : 10,
                            12,
                            0),
                        child: Text(
                          body.isEmpty ? 'El mensaje aparecerá aquí…' : body,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: body.isEmpty
                                ? AppColors.ctText3
                                : AppColors.ctText,
                          ),
                        ),
                      ),
                      // Footer
                      if (footer.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 4, 12, 0),
                          child: Text(
                            footer,
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 11,
                              color: AppColors.ctText2,
                            ),
                          ),
                        ),
                      // Timestamp row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              time,
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                color: AppColors.ctText2,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.done_all_rounded,
                                size: 13, color: AppColors.ctTeal),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── footer action bar ────────────────────────────────────────────────────────

  Widget _buildFooterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton(
            onPressed:
                _submitting ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ctBorder2),
              foregroundColor: AppColors.ctText2,
              textStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctTeal,
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  AppColors.ctTeal.withValues(alpha: 0.5),
              textStyle: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Enviar a revisión'),
          ),
        ],
      ),
    );
  }

  // ── utility ──────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText2,
        ),
      );

  String _headerTypeLabel(_HeaderType t) {
    switch (t) {
      case _HeaderType.none:  return 'Ninguno';
      case _HeaderType.text:  return 'Texto';
      case _HeaderType.image: return 'Imagen';
      case _HeaderType.video: return 'Video';
      case _HeaderType.file:  return 'Archivo';
    }
  }

  IconData _headerTypeIcon(_HeaderType t) {
    switch (t) {
      case _HeaderType.image: return Icons.image_outlined;
      case _HeaderType.video: return Icons.videocam_outlined;
      case _HeaderType.file:  return Icons.attach_file_rounded;
      default:                return Icons.image_outlined;
    }
  }
}

// ── Chip de tipo de encabezado ─────────────────────────────────────────────────

class _HeaderChip extends StatefulWidget {
  const _HeaderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_HeaderChip> createState() => _HeaderChipState();
}

class _HeaderChipState extends State<_HeaderChip> {
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
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.ctTeal
                : (_hovered ? AppColors.ctSurface2 : AppColors.ctSurface),
            border: Border.all(
              color: widget.selected ? AppColors.ctTeal : AppColors.ctBorder,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.selected ? Colors.white : AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}
