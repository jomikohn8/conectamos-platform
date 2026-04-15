import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';
import 'whatsapp_groups_screen.dart';

// ── Tabs ──────────────────────────────────────────────────────────────────────

enum _WaTab { credentials, templates, welcome, groups }

// ── Pantalla ──────────────────────────────────────────────────────────────────

class WhatsAppConfigScreen extends ConsumerStatefulWidget {
  const WhatsAppConfigScreen({super.key});

  @override
  ConsumerState<WhatsAppConfigScreen> createState() =>
      _WhatsAppConfigScreenState();
}

class _WhatsAppConfigScreenState extends ConsumerState<WhatsAppConfigScreen> {
  _WaTab _tab = _WaTab.credentials;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBar(
          currentTab: _tab,
          onTabSelected: (t) => setState(() => _tab = t),
        ),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildTabContent() {
    switch (_tab) {
      case _WaTab.credentials:
        return const _CredentialsTab();
      case _WaTab.templates:
        return const _TemplatesTab();
      case _WaTab.welcome:
        return const _WelcomeTab();
      case _WaTab.groups:
        return const WhatsAppGroupsScreen();
    }
  }
}

// ── Action bar con tabs ───────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.currentTab,
    required this.onTabSelected,
  });
  final _WaTab currentTab;
  final ValueChanged<_WaTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 12, 22, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WhatsApp Business API',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Meta Cloud API — configuración y gestión',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                _Tab(
                  label: 'Credenciales',
                  active: currentTab == _WaTab.credentials,
                  onTap: () => onTabSelected(_WaTab.credentials),
                ),
                _Tab(
                  label: 'Plantillas',
                  active: currentTab == _WaTab.templates,
                  onTap: () => onTabSelected(_WaTab.templates),
                ),
                _Tab(
                  label: 'Msg. bienvenida',
                  active: currentTab == _WaTab.welcome,
                  onTap: () => onTabSelected(_WaTab.welcome),
                ),
                _Tab(
                  label: 'Grupos WhatsApp',
                  active: currentTab == _WaTab.groups,
                  onTap: () => onTabSelected(_WaTab.groups),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatefulWidget {
  const _Tab({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: widget.active
                    ? AppColors.ctTeal
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight:
                  widget.active ? FontWeight.w600 : FontWeight.w500,
              color: widget.active
                  ? AppColors.ctTeal
                  : _hovered
                      ? AppColors.ctText
                      : AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}

// ── FutureProvider para credenciales ─────────────────────────────────────────

final _credentialsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return null;
    final res = await ApiClient.instance.get('/tenants/$tenantId');
    return Map<String, dynamic>.from(res.data as Map);
  },
);

// ── Tab Credenciales ──────────────────────────────────────────────────────────

class _CredentialsTab extends ConsumerStatefulWidget {
  const _CredentialsTab();

  @override
  ConsumerState<_CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends ConsumerState<_CredentialsTab> {
  final _phoneIdCtrl = TextEditingController();
  final _wabaIdCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();

  bool _saving = false;
  String? _error;
  String? _success;
  String? _loadedForTenant;

  @override
  void dispose() {
    _phoneIdCtrl.dispose();
    _wabaIdCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String tenantId) async {
    if (tenantId.isEmpty) return;
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiClient.instance.patch(
        '/tenants/$tenantId/credentials',
        data: {
          'wa_phone_number_id': _phoneIdCtrl.text.trim(),
          'wa_waba_id': _wabaIdCtrl.text.trim(),
          'wa_token': _tokenCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() { _saving = false; _success = 'Credenciales guardadas correctamente'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = detail ?? 'Error al guardar las credenciales'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error al guardar: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId = ref.watch(activeTenantIdProvider);

    ref.listen<AsyncValue<Map<String, dynamic>?>>(
      _credentialsProvider(tenantId),
      (_, next) {
        next.whenData((data) {
          if (data != null && _loadedForTenant != tenantId) {
            _loadedForTenant = tenantId;
            _phoneIdCtrl.text = data['wa_phone_number_id']?.toString() ?? '';
            _wabaIdCtrl.text = data['wa_waba_id']?.toString() ?? '';
            _tokenCtrl.text = data['wa_token']?.toString() ?? '';
          }
        });
      },
    );

    final credAsync = ref.watch(_credentialsProvider(tenantId));

    return credAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.ctTeal),
      ),
      error: (e, _) => Center(
        child: Text(
          'Error al cargar credenciales: $e',
          style: const TextStyle(fontFamily: 'Inter', color: AppColors.ctText2),
        ),
      ),
      data: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              title: 'Credenciales de Meta Cloud API',
              subtitle:
                  'Configura los identificadores de tu cuenta de WhatsApp Business',
              child: Column(
                children: [
                  _FormField(
                    label: 'Phone Number ID',
                    controller: _phoneIdCtrl,
                    placeholder: 'Ej: 1234567890123456',
                    hint: 'Encuéntralo en Meta for Developers → WhatsApp → Configuración',
                  ),
                  const SizedBox(height: 16),
                  _FormField(
                    label: 'WABA ID (WhatsApp Business Account)',
                    controller: _wabaIdCtrl,
                    placeholder: 'Ej: 9876543210987654',
                    hint: 'ID de tu cuenta de WhatsApp Business en Meta',
                  ),
                  const SizedBox(height: 16),
                  _FormField(
                    label: 'Token de acceso',
                    controller: _tokenCtrl,
                    placeholder: 'EAABsbCS0zC4BO...',
                    obscureText: true,
                    hint: 'Token permanente o de larga duración de tu app de Meta',
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    _FeedbackBanner(message: _error!, isError: true),
                    const SizedBox(height: 12),
                  ],
                  if (_success != null) ...[
                    _FeedbackBanner(message: _success!, isError: false),
                    const SizedBox(height: 12),
                  ],
                  Align(
                    alignment: Alignment.centerRight,
                    child: _SaveButton(
                      loading: _saving,
                      onTap: _saving ? null : () => _save(tenantId),
                    ),
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

// ── FutureProvider para plantillas ───────────────────────────────────────────

final _templatesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return [];
    final res = await ApiClient.instance.get(
      '/templates',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = res.data;
    final List raw = data is List
        ? data
        : (data['templates'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  },
);

// ── FutureProvider para plantilla default del sistema ─────────────────────────

final _defaultTemplateProvider =
    FutureProvider.autoDispose<Map<String, dynamic>?>(
  (ref) async {
    try {
      final res = await ApiClient.instance.get('/templates/default');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  },
);

// ── Helper: resuelve preview con valores de ejemplo ───────────────────────────

String _resolveTemplatePreview(Map<String, dynamic> template) {
  const examples = <String, String>{
    'nombre_operador':   'José Miguel',
    'telefono_operador': '5215559537449',
    'nombre_tenant':     'TMR-Prixz',
    'fecha_hoy':         '14/04/2026',
    'hora_actual':       '10:30 AM',
  };
  String preview = template['body_text']?.toString() ?? '';
  final vars = template['variables'];
  if (vars is List) {
    for (final v in vars) {
      if (v is! Map) continue;
      final slot = v['slot'] as int? ?? 0;
      final type = v['type'] as String? ?? 'free';
      final key  = v['key']  as String? ?? '';
      final val  = type == 'system'
          ? (examples[key] ?? '[$key]')
          : (key.isNotEmpty ? '[$key]' : '{{$slot}}');
      if (slot > 0) preview = preview.replaceAll('{{$slot}}', val);
    }
  }
  return preview;
}

// ── Tab Plantillas ────────────────────────────────────────────────────────────

class _TemplatesTab extends ConsumerStatefulWidget {
  const _TemplatesTab();

  @override
  ConsumerState<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends ConsumerState<_TemplatesTab> {
  bool _syncing = false;

  Future<void> _sync(String tenantId) async {
    if (tenantId.isEmpty) return;
    setState(() => _syncing = true);
    try {
      await ApiClient.instance.post(
        '/templates/sync',
        queryParameters: {'tenant_id': tenantId},
      );
      if (!mounted) return;
      ref.invalidate(_templatesProvider(tenantId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(_waSnack('Error al sincronizar: $e'));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId      = ref.watch(activeTenantIdProvider);
    final templatesAsync = ref.watch(_templatesProvider(tenantId));

    return Column(
      children: [
        // Header bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
          ),
          child: Row(
            children: [
              // Info note
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: AppColors.ctText3,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Solo las plantillas APPROVED pueden enviarse. PENDING y REJECTED no están disponibles para mensajes.',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.ctText3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Sync button
              _WaOutlineButton(
                label: _syncing ? 'Sincronizando...' : 'Sincronizar',
                icon: Icons.sync_rounded,
                loading: _syncing,
                onTap: _syncing ? null : () => _sync(tenantId),
              ),
              const SizedBox(width: 8),
              // New template button
              _WaPrimaryButton(
                label: '+ Nueva plantilla',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _NewTemplateDialog(
                    tenantId: tenantId,
                    onCreated: () {
                      ref.invalidate(_templatesProvider(tenantId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        _waSnack('Plantilla enviada a Meta para aprobación'),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Expanded(
          child: templatesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.ctTeal),
            ),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 32, color: AppColors.ctText3),
                  const SizedBox(height: 12),
                  Text(
                    'Error al cargar plantillas: $e',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.ctText2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(_templatesProvider(tenantId)),
                    child: const Text(
                      'Reintentar',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.ctTeal),
                    ),
                  ),
                ],
              ),
            ),
            data: (templates) => templates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.format_list_bulleted_rounded,
                              size: 24, color: AppColors.ctText3),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Sin plantillas',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Crea una plantilla o sincroniza con Meta.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: _TemplatesTable(
                      templates: templates,
                      tenantId: tenantId,
                      onRefresh: () =>
                          ref.invalidate(_templatesProvider(tenantId)),
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Tabla de plantillas ───────────────────────────────────────────────────────

class _TemplatesTable extends StatelessWidget {
  const _TemplatesTable({
    required this.templates,
    required this.tenantId,
    required this.onRefresh,
  });
  final List<Map<String, dynamic>> templates;
  final String tenantId;
  final VoidCallback onRefresh;

  static const _h = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.ctText2,
    letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('NOMBRE', style: _h)),
                Expanded(flex: 2, child: Text('CATEGORÍA', style: _h)),
                Expanded(flex: 1, child: Text('IDIOMA', style: _h)),
                Expanded(flex: 3, child: Text('VARIABLES', style: _h)),
                Expanded(flex: 2, child: Text('STATUS', style: _h)),
                SizedBox(width: 120),
              ],
            ),
          ),
          ...templates.asMap().entries.map((entry) {
            final i = entry.key;
            final t = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: AppColors.ctBorder),
                _TemplateRow(
                  template: t,
                  tenantId: tenantId,
                  isLast: i == templates.length - 1,
                  onRefresh: onRefresh,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Fila de plantilla ─────────────────────────────────────────────────────────

class _TemplateRow extends StatefulWidget {
  const _TemplateRow({
    required this.template,
    required this.tenantId,
    required this.isLast,
    required this.onRefresh,
  });
  final Map<String, dynamic> template;
  final String tenantId;
  final bool isLast;
  final VoidCallback onRefresh;

  @override
  State<_TemplateRow> createState() => _TemplateRowState();
}

class _TemplateRowState extends State<_TemplateRow> {
  bool _hovered  = false;
  bool _deleting = false;

  String get _id       => widget.template['id']?.toString() ?? '';
  String get _name     => widget.template['name']?.toString() ?? '';
  String get _category => widget.template['category']?.toString() ?? '';
  String get _language => widget.template['language']?.toString() ?? '';
  String get _status   => widget.template['status']?.toString().toUpperCase() ?? '';
  bool   get _isWelcome => widget.template['is_welcome'] == true;

  static const _sysVarDesc = <String, String>{
    'nombre_operador':   'Nombre del operador',
    'telefono_operador': 'Teléfono del operador',
    'nombre_tenant':     'Nombre de la empresa',
    'fecha_hoy':         'Fecha de hoy',
    'hora_actual':       'Hora actual',
  };

  List<Map<String, dynamic>> get _varList {
    final v = widget.template['variables'];
    if (v is! List) return [];
    return v.map((e) {
      if (e is Map) return Map<String, dynamic>.from(e);
      return <String, dynamic>{'slot': 0, 'type': 'free', 'key': e.toString()};
    }).toList();
  }

  String _varLabel(Map<String, dynamic> v) {
    final type = v['type'] as String? ?? 'free';
    final key  = v['key']  as String? ?? '';
    if (type == 'system') return _sysVarDesc[key] ?? key;
    return key.isNotEmpty ? '[$key]' : '[variable]';
  }

  void _showDetail() {
    showDialog(
      context: context,
      builder: (_) => _TemplateDetailDialog(template: widget.template),
    );
  }

  void _copy() {
    final origName = _name;
    showDialog(
      context: context,
      builder: (_) => _NewTemplateDialog(
        tenantId:         widget.tenantId,
        onCreated:        widget.onRefresh,
        initialName:      '${origName}_v2',
        initialBody:      widget.template['body_text']?.toString(),
        initialCategory:  _category,
        initialLanguage:  _language,
        isCopy:           true,
      ),
    );
  }

  void _sendTest() {
    showDialog(
      context: context,
      builder: (_) => _SendTestDialog(
        template: widget.template,
        tenantId: widget.tenantId,
      ),
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.ctSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.ctBorder),
        ),
        title: const Text(
          'Eliminar plantilla',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.ctText,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar la plantilla "$_name"? Esta acción no se puede deshacer.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.ctText2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                  fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctRedText),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _deleting = true);
    try {
      await ApiClient.instance.delete('/templates/$_id');
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(_waSnack('Error al eliminar: $e'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = widget.isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(7),
          )
        : BorderRadius.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
          borderRadius: borderRadius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Nombre
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  if (_isWelcome) ...[
                    const Icon(Icons.star_rounded,
                        size: 13, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                  ],
                  Flexible(
                    child: Text(
                      _name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctText,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Categoría
            Expanded(
              flex: 2,
              child: Text(
                _category,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            ),

            // Idioma
            Expanded(
              flex: 1,
              child: Text(
                _language,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            ),

            // Variables
            Expanded(
              flex: 3,
              child: Builder(builder: (_) {
                final vars = _varList;
                if (vars.isEmpty) {
                  return const Text(
                    '—',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.ctText3),
                  );
                }
                final shown = vars.length > 2 ? vars.sublist(0, 2) : vars;
                final extra = vars.length - shown.length;
                return Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    ...shown.map((v) {
                      final isSystem =
                          (v['type'] as String? ?? 'free') == 'system';
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSystem
                              ? const Color(0xFFDCFCE7)
                              : AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _varLabel(v),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isSystem
                                ? const Color(0xFF065F46)
                                : AppColors.ctText2,
                          ),
                        ),
                      );
                    }),
                    if (extra > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '+$extra más',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),

            // Status badge
            Expanded(
              flex: 2,
              child: _TemplateBadge(status: _status),
            ),

            // Acciones
            SizedBox(
              width: 120,
              child: _deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ctTeal,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _RowActionIcon(
                          icon: Icons.visibility_outlined,
                          tooltip: 'Ver detalle',
                          onTap: _showDetail,
                        ),
                        _RowActionIcon(
                          icon: Icons.copy_outlined,
                          tooltip: 'Duplicar y editar',
                          onTap: _copy,
                        ),
                        _RowActionIcon(
                          icon: Icons.send_rounded,
                          tooltip: 'Enviar prueba',
                          onTap: _sendTest,
                        ),
                        _RowActionIcon(
                          icon: Icons.delete_outline_rounded,
                          tooltip: 'Eliminar',
                          onTap: _delete,
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

// ── Badge de status de plantilla ──────────────────────────────────────────────

class _TemplateBadge extends StatelessWidget {
  const _TemplateBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;

    switch (status) {
      case 'APPROVED':
        bg        = AppColors.ctOkBg;
        textColor = AppColors.ctOkText;
      case 'PENDING':
        bg        = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
      case 'REJECTED':
        bg        = AppColors.ctRedBg;
        textColor = AppColors.ctRedText;
      default:
        bg        = AppColors.ctSurface2;
        textColor = AppColors.ctText2;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.isEmpty ? '—' : status,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Modelo de configuración de variable ───────────────────────────────────────

class _VarConfig {
  int slot;    // el número {{n}} real del cuerpo
  String type; // 'system' | 'free'
  String key;
  _VarConfig({required this.slot, required this.type, required this.key});
}

// ── Modal nueva plantilla ─────────────────────────────────────────────────────

class _NewTemplateDialog extends StatefulWidget {
  const _NewTemplateDialog({
    required this.tenantId,
    required this.onCreated,
    this.initialName,
    this.initialBody,
    this.initialCategory,
    this.initialLanguage,
    this.isCopy = false,
  });
  final String tenantId;
  final VoidCallback onCreated;
  final String? initialName;
  final String? initialBody;
  final String? initialCategory;
  final String? initialLanguage;
  final bool isCopy;

  @override
  State<_NewTemplateDialog> createState() => _NewTemplateDialogState();
}

class _NewTemplateDialogState extends State<_NewTemplateDialog> {
  final _nameCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String _category = 'UTILITY';
  String _language = 'es';
  final List<_VarConfig> _varConfigs = [];
  final List<TextEditingController> _freeKeyCtrls = [];
  bool _sending = false;
  String? _error;

  static const _categories = ['UTILITY', 'MARKETING', 'AUTHENTICATION'];
  static const _languages = [
    {'code': 'es', 'label': 'Español (es)'},
    {'code': 'en', 'label': 'Inglés (en)'},
  ];

  // Catálogo: clave → [descripción, valor_ejemplo]
  static const _sysVarDesc = <String, String>{
    'nombre_operador':   'Nombre del operador',
    'telefono_operador': 'Teléfono del operador',
    'nombre_tenant':     'Nombre de la empresa',
    'fecha_hoy':         'Fecha de hoy',
    'hora_actual':       'Hora actual',
  };
  static const _sysVarExample = <String, String>{
    'nombre_operador':   'José Miguel',
    'telefono_operador': '5215559537449',
    'nombre_tenant':     'TMR-Prixz',
    'fecha_hoy':         '14/04/2026',
    'hora_actual':       '10:30 AM',
  };

  @override
  void initState() {
    super.initState();
    _bodyCtrl.addListener(_syncVarsFromBody);
    if (widget.initialBody != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialName != null) {
          _nameCtrl.text = widget.initialName!;
          setState(() {});
        }
        if (widget.initialCategory != null) {
          setState(() => _category = widget.initialCategory!);
        }
        if (widget.initialLanguage != null) {
          setState(() => _language = widget.initialLanguage!);
        }
        // Setting body triggers _syncVarsFromBody via listener
        _bodyCtrl.text = widget.initialBody!;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bodyCtrl.removeListener(_syncVarsFromBody);
    _bodyCtrl.dispose();
    for (final c in _freeKeyCtrls) { c.dispose(); }
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _toSnakeCase(String input) {
    return input
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_]'), '')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  // Devuelve los slots únicos encontrados en el cuerpo, ordenados.
  List<int> _detectSlots(String body) {
    return RegExp(r'\{\{(\d+)\}\}')
        .allMatches(body)
        .map((m) => int.tryParse(m.group(1)!) ?? 0)
        .where((n) => n > 0)
        .toSet()
        .toList()
      ..sort();
  }

  String _buildPreview() {
    String preview = _bodyCtrl.text;
    for (int i = 0; i < _varConfigs.length; i++) {
      final cfg = _varConfigs[i];
      final String val;
      if (cfg.type == 'system') {
        val = _sysVarExample[cfg.key] ?? '{{${cfg.slot}}}';
      } else {
        final freeKey = _freeKeyCtrls[i].text.trim();
        val = freeKey.isNotEmpty ? '[$freeKey]' : '{{${cfg.slot}}}';
      }
      preview = preview.replaceAll('{{${cfg.slot}}}', val);
    }
    return preview;
  }

  void _syncVarsFromBody() {
    final slots = _detectSlots(_bodyCtrl.text);

    // Compara con el estado actual; si ya coincide, no hace nada.
    final current = _varConfigs.map((c) => c.slot).toList();
    if (slots.length == current.length &&
        List.generate(slots.length, (i) => slots[i] == current[i])
            .every((ok) => ok)) { return; }

    setState(() {
      // Reutiliza configs y controllers para slots que ya existían.
      final prevConfigs = {for (final c in _varConfigs) c.slot: c};
      final prevCtrls = {
        for (int i = 0; i < _varConfigs.length; i++) _varConfigs[i].slot: _freeKeyCtrls[i]
      };

      // Libera controllers de slots eliminados.
      for (final slot in prevCtrls.keys) {
        if (!slots.contains(slot)) prevCtrls[slot]!.dispose();
      }

      _varConfigs.clear();
      _freeKeyCtrls.clear();

      for (final slot in slots) {
        if (prevConfigs.containsKey(slot)) {
          _varConfigs.add(prevConfigs[slot]!);
          _freeKeyCtrls.add(prevCtrls[slot]!);
        } else {
          _varConfigs.add(_VarConfig(
            slot: slot,
            type: 'system',
            key:  _sysVarDesc.keys.first,
          ));
          final ctrl = TextEditingController();
          ctrl.addListener(() => setState(() {}));
          _freeKeyCtrls.add(ctrl);
        }
      }
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _send() async {
    final name = _toSnakeCase(_nameCtrl.text);
    final body = _bodyCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Ingresa el nombre de la plantilla');
      return;
    }
    if (body.isEmpty) {
      setState(() => _error = 'Ingresa el cuerpo del mensaje');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await ApiClient.instance.post(
        '/templates',
        data: {
          'tenant_id':  widget.tenantId,
          'name':       name,
          'category':   _category,
          'language':   _language,
          'body_text':  body,
          'variables':  List.generate(_varConfigs.length, (i) {
            final cfg = _varConfigs[i];
            return {
              'slot': cfg.slot,
              'type': cfg.type,
              'key':  cfg.type == 'system'
                  ? cfg.key
                  : _freeKeyCtrls[i].text.trim(),
            };
          }),
          'is_welcome': false,
        },
        options: Options(
          validateStatus: (s) => s != null && s >= 200 && s < 300,
        ),
      );
      if (!mounted) return;
      widget.onCreated();
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _sending = false;
        _error   = detail ?? 'Error al crear la plantilla';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _error = 'Error: $e'; });
    }
  }

  // ── Variable row ──────────────────────────────────────────────────────────

  Widget _buildVarRow(int i) {
    final cfg = _varConfigs[i];
    final isSystem = cfg.type == 'system';
    final chipVal = isSystem
        ? (_sysVarExample[cfg.key] ?? '')
        : (_freeKeyCtrls[i].text.trim().isNotEmpty
            ? '[${_freeKeyCtrls[i].text.trim()}]'
            : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.ctBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Variable {{${cfg.slot}}}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText,
                  ),
                ),
                const Spacer(),
                _VarTypeToggle(
                  isSystem: isSystem,
                  onChanged: (sys) => setState(() {
                    _varConfigs[i] = _VarConfig(
                      slot: cfg.slot,
                      type: sys ? 'system' : 'free',
                      key:  sys ? _sysVarDesc.keys.first : '',
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isSystem)
              _tplDropdown<String>(
                value: _sysVarDesc.containsKey(cfg.key)
                    ? cfg.key
                    : _sysVarDesc.keys.first,
                items: _sysVarDesc.entries
                    .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _varConfigs[i].key = v);
                },
              )
            else
              TextField(
                controller: _freeKeyCtrls[i],
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.ctText),
                decoration: _tplInputDecoration(
                    'Nombre descriptivo (ej: numero_pedido)'),
              ),
            if (chipVal.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSystem
                      ? const Color(0xFFDCFCE7)
                      : AppColors.ctSurface2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  chipVal,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSystem
                        ? const Color(0xFF065F46)
                        : AppColors.ctText2,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final preview = _buildPreview();

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 740),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                children: [
                  Text(
                    widget.isCopy ? 'Duplicar plantilla' : 'Nueva plantilla',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                ],
              ),
            ),
            // Body (scrollable)
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nota de copia
                    if (widget.isCopy) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14, color: Color(0xFF2563EB)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Se creará una nueva plantilla. La original no se modificará.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    // Nombre
                    _TplField(
                      label: 'Nombre',
                      child: TextField(
                        controller: _nameCtrl,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText),
                        decoration: _tplInputDecoration(
                          'ej: confirmacion_cita',
                          hint: 'Se convierte automáticamente a snake_case',
                        ),
                      ),
                    ),
                    if (_nameCtrl.text.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Nombre final: ${_toSnakeCase(_nameCtrl.text)}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.ctTeal,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),

                    // Categoría + Idioma
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _TplField(
                            label: 'Categoría',
                            child: _tplDropdown<String>(
                              value: _category,
                              items: _categories
                                  .map((c) => DropdownMenuItem(
                                      value: c, child: Text(c)))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _category = v);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TplField(
                            label: 'Idioma',
                            child: _tplDropdown<String>(
                              value: _language,
                              items: _languages
                                  .map((l) => DropdownMenuItem(
                                        value: l['code'],
                                        child: Text(l['label']!),
                                      ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _language = v);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Cuerpo
                    _TplField(
                      label: 'Cuerpo del mensaje',
                      child: TextField(
                        controller: _bodyCtrl,
                        minLines: 3,
                        maxLines: 6,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText),
                        decoration: _tplInputDecoration(
                          'Hola {{1}}, tu cita es el {{2}}.',
                          hint: 'Usa {{1}}, {{2}}… para variables',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Variables
                    if (_varConfigs.isEmpty)
                      const Text(
                        'Usa {{1}}, {{2}}… en el cuerpo para agregar variables.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.ctText3,
                        ),
                      )
                    else ...[
                      const Text(
                        'Variables',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Las variables del sistema se llenan automáticamente al enviar. '
                        'Las variables libres las llena el supervisor al momento de enviar el mensaje.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.ctText3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_varConfigs.length, _buildVarRow),
                    ],
                    const SizedBox(height: 14),

                    // Preview
                    if (_bodyCtrl.text.isNotEmpty) ...[
                      const Text(
                        'Preview',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                          border:
                              Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Text(
                          preview,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Error
                    if (_error != null) ...[
                      _FeedbackBanner(message: _error!, isError: true),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WaOutlineButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _WaPrimaryButton(
                    label: 'Crear plantilla',
                    loading: _sending,
                    onTap: _sending ? null : _send,
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

// ── Toggle sistema / libre ────────────────────────────────────────────────────

class _VarTypeToggle extends StatelessWidget {
  const _VarTypeToggle({
    required this.isSystem,
    required this.onChanged,
  });
  final bool isSystem;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            label: 'Del sistema',
            active: isSystem,
            onTap: () => onChanged(true),
          ),
          _ToggleOption(
            label: 'Libre',
            active: !isSystem,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  const _ToggleOption({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.ctTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.ctNavy : AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}

// ── Helpers de formulario para plantillas ─────────────────────────────────────

class _TplField extends StatelessWidget {
  const _TplField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

InputDecoration _tplInputDecoration(String placeholder, {String? hint}) {
  return InputDecoration(
    hintText: placeholder,
    hintStyle: const TextStyle(
        fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText3),
    helperText: hint,
    helperStyle: const TextStyle(
        fontFamily: 'Inter', fontSize: 11, color: AppColors.ctText3),
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
      borderSide: const BorderSide(color: AppColors.ctTeal, width: 1.5),
    ),
  );
}

Widget _tplDropdown<T>({
  required T value,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.ctSurface2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.ctBorder2),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        isDense: true,
        style: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 16,
          color: AppColors.ctText3,
        ),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

// ── Botones locales para este tab ─────────────────────────────────────────────

class _WaPrimaryButton extends StatefulWidget {
  const _WaPrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  State<_WaPrimaryButton> createState() => _WaPrimaryButtonState();
}

class _WaPrimaryButtonState extends State<_WaPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? AppColors.ctTeal.withValues(alpha: 0.5)
                : _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(7),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.ctNavy),
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctNavy,
                  ),
                ),
        ),
      ),
    );
  }
}

class _WaOutlineButton extends StatefulWidget {
  const _WaOutlineButton({
    required this.label,
    this.icon,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  State<_WaOutlineButton> createState() => _WaOutlineButtonState();
}

class _WaOutlineButtonState extends State<_WaOutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ctText2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon!, size: 13, color: AppColors.ctText2),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── SnackBar helper local ─────────────────────────────────────────────────────

SnackBar _waSnack(String msg) => SnackBar(
      content:
          Text(msg, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
      backgroundColor: AppColors.ctNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    );

// ── Tab Bienvenida ────────────────────────────────────────────────────────────

class _WelcomeTab extends ConsumerStatefulWidget {
  const _WelcomeTab();

  @override
  ConsumerState<_WelcomeTab> createState() => _WelcomeTabState();
}

class _WelcomeTabState extends ConsumerState<_WelcomeTab> {
  bool _saving = false;
  String? _error;
  String? _success;

  Future<void> _setWelcomeTemplate(String tenantId, String? templateId) async {
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiClient.instance.patch(
        '/tenants/$tenantId/welcome-template',
        data: {'welcome_template_id': templateId},
        options: Options(validateStatus: (s) => s != null && s >= 200 && s < 300),
      );
      if (!mounted) return;
      ref.invalidate(_credentialsProvider(tenantId));
      setState(() { _saving = false; _success = 'Plantilla de bienvenida actualizada'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = detail ?? 'Error al guardar'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId     = ref.watch(activeTenantIdProvider);
    final tenantAsync  = ref.watch(_credentialsProvider(tenantId));
    final tplsAsync    = ref.watch(_templatesProvider(tenantId));
    final defaultAsync = ref.watch(_defaultTemplateProvider);

    return tenantAsync.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.ctTeal)),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(
                fontFamily: 'Inter', color: AppColors.ctText2)),
      ),
      data: (tenant) {
        if (tenant == null) return const SizedBox.shrink();

        final currentId = tenant['welcome_template_id']?.toString() ?? '';
        final isActive  = currentId.isNotEmpty;

        final approved = tplsAsync.maybeWhen(
          data: (tpls) => tpls
              .where((t) =>
                  t['status']?.toString().toUpperCase() == 'APPROVED')
              .toList(),
          orElse: () => <Map<String, dynamic>>[],
        );

        final systemDefault = approved.isEmpty
            ? defaultAsync.maybeWhen(data: (d) => d, orElse: () => null)
            : null;

        final allItems = <Map<String, dynamic>>[
          if (systemDefault != null) {...systemDefault, '_is_default': true},
          ...approved,
        ];

        final validIds =
            allItems.map((t) => t['id']?.toString() ?? '').toSet();
        final selectedId =
            validIds.contains(currentId) ? currentId : null;

        final selectedTpl = selectedId != null
            ? allItems.firstWhere(
                (t) => t['id']?.toString() == selectedId,
                orElse: () => <String, dynamic>{},
              )
            : <String, dynamic>{};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: _SectionCard(
            title: 'Mensaje de bienvenida a operadores',
            subtitle:
                'Este mensaje se envía automáticamente cuando se da de alta un nuevo operador.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Estado
                Row(
                  children: [
                    const Text(
                      'Estado:',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFDCFCE7)
                            : AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Activa' : 'Sin configurar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF065F46)
                              : AppColors.ctText2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Selector
                const Text(
                  'Plantilla de bienvenida',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctText,
                  ),
                ),
                const SizedBox(height: 8),
                if (allItems.isEmpty)
                  const Text(
                    'No hay plantillas APPROVED disponibles. '
                    'Crea y aprueba una plantilla primero.',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.ctText3),
                  )
                else
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.ctSurface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ctBorder2),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedId,
                        isExpanded: true,
                        isDense: true,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: AppColors.ctText3,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text(
                              'Sin plantilla',
                              style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.ctText3),
                            ),
                          ),
                          ...allItems.map((t) {
                            final id        = t['id']?.toString() ?? '';
                            final name      = t['name']?.toString() ?? '';
                            final isDefault = t['_is_default'] == true;
                            return DropdownMenuItem<String?>(
                              value: id,
                              child: Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  if (isDefault) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.ctSurface2,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppColors.ctBorder),
                                      ),
                                      child: const Text(
                                        'Default del sistema',
                                        style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            color: AppColors.ctText3),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged:
                            _saving ? null : (v) => _setWelcomeTemplate(tenantId, v),
                      ),
                    ),
                  ),

                // Preview
                if (selectedTpl.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _DetailLabel('Preview del mensaje'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Text(
                      _resolveTemplatePreview(selectedTpl),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF065F46),
                      ),
                    ),
                  ),
                ],

                // Feedback
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(message: _error!, isError: true),
                ],
                if (_success != null) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(message: _success!, isError: false),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Dialog de detalle de plantilla ────────────────────────────────────────────

class _TemplateDetailDialog extends StatelessWidget {
  const _TemplateDetailDialog({required this.template});
  final Map<String, dynamic> template;

  static const _sysVarDesc = <String, String>{
    'nombre_operador':   'Nombre del operador',
    'telefono_operador': 'Teléfono del operador',
    'nombre_tenant':     'Nombre de la empresa',
    'fecha_hoy':         'Fecha de hoy',
    'hora_actual':       'Hora actual',
  };

  @override
  Widget build(BuildContext context) {
    final name     = template['name']?.toString() ?? '';
    final category = template['category']?.toString() ?? '';
    final language = template['language']?.toString() ?? '';
    final status   = template['status']?.toString().toUpperCase() ?? '';
    final vars     = template['variables'];
    final varList  = vars is List
        ? vars
            .map((e) => e is Map
                ? Map<String, dynamic>.from(e)
                : <String, dynamic>{})
            .where((m) => m.isNotEmpty)
            .toList()
        : <Map<String, dynamic>>[];

    String varLabel(Map<String, dynamic> v) {
      final type = v['type'] as String? ?? 'free';
      final key  = v['key']  as String? ?? '';
      return type == 'system'
          ? (_sysVarDesc[key] ?? key)
          : (key.isNotEmpty ? '[$key]' : '[variable]');
    }

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 660),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctText,
                      ),
                    ),
                  ),
                  _TemplateBadge(status: status),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _DetailChip(label: category),
                        const SizedBox(width: 8),
                        _DetailChip(label: language),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _DetailLabel('Cuerpo del mensaje'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ctBorder),
                      ),
                      child: Text(
                        template['body_text']?.toString() ?? '',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.ctText,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (varList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const _DetailLabel('Variables'),
                      const SizedBox(height: 8),
                      ...varList.map((v) {
                        final slot     = v['slot'] as int? ?? 0;
                        final type     = v['type'] as String? ?? 'free';
                        final isSystem = type == 'system';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.ctSurface2,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '{{$slot}}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    color: AppColors.ctText3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isSystem
                                      ? const Color(0xFFDCFCE7)
                                      : AppColors.ctSurface2,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isSystem ? 'Sistema' : 'Libre',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSystem
                                        ? const Color(0xFF065F46)
                                        : AppColors.ctText2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                varLabel(v),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color: AppColors.ctText2,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 16),
                    const _DetailLabel('Preview'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        _resolveTemplatePreview(template),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WaOutlineButton(
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

// ── Dialog enviar prueba ──────────────────────────────────────────────────────

class _SendTestDialog extends ConsumerStatefulWidget {
  const _SendTestDialog({
    required this.template,
    required this.tenantId,
  });
  final Map<String, dynamic> template;
  final String tenantId;

  @override
  ConsumerState<_SendTestDialog> createState() => _SendTestDialogState();
}

class _SendTestDialogState extends ConsumerState<_SendTestDialog> {
  final _phoneCtrl = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void initState() {
    super.initState();
    _loadPhone();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhone() async {
    try {
      final uid = ref.read(currentUserProvider)?.id ?? '';
      if (uid.isEmpty) return;
      final res = await ApiClient.instance.get(
        '/iam/users',
        queryParameters: {'tenant_id': widget.tenantId},
      );
      final List rows = res.data is List ? res.data as List : [];
      final match = rows.cast<Map>().firstWhere(
        (r) => r['user_id']?.toString() == uid,
        orElse: () => <String, dynamic>{},
      );
      final phone = match['telefono']?.toString() ?? '';
      if (mounted && phone.isNotEmpty) {
        setState(() => _phoneCtrl.text = phone);
      }
    } catch (_) {}
  }

  Future<void> _send() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Ingresa un número de teléfono');
      return;
    }
    setState(() { _sending = true; _error = null; _success = null; });
    try {
      final preview = _resolveTemplatePreview(widget.template);
      await ApiClient.instance.post(
        '/messages/send',
        data: {
          'to':        phone,
          'message':   preview,
          'tenant_id': widget.tenantId,
        },
        options: Options(
            validateStatus: (s) => s != null && s >= 200 && s < 300),
      );
      if (!mounted) return;
      setState(() { _sending = false; _success = 'Mensaje enviado correctamente'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _sending = false;
        _error   = detail ?? 'Error al enviar el mensaje';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _resolveTemplatePreview(widget.template);
    final name    = widget.template['name']?.toString() ?? '';

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border:
                    Border(bottom: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enviar prueba',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Plantilla: $name',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _TplField(
                      label: 'Número de teléfono destino',
                      child: TextField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText),
                        decoration: _tplInputDecoration(
                          '+52 55 1234 5678',
                          hint: 'Incluye código de país (ej: 521)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const _DetailLabel('Mensaje que se enviará'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFFBBF7D0)),
                      ),
                      child: Text(
                        preview,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: Color(0xFF065F46),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      _FeedbackBanner(message: _error!, isError: true),
                    ],
                    if (_success != null) ...[
                      const SizedBox(height: 14),
                      _FeedbackBanner(message: _success!, isError: false),
                    ],
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _WaOutlineButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _WaPrimaryButton(
                    label: 'Enviar prueba',
                    loading: _sending,
                    onTap: (_sending || _success != null) ? null : _send,
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _RowActionIcon extends StatelessWidget {
  const _RowActionIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 15, color: AppColors.ctText3),
      tooltip: tooltip,
      onPressed: onTap,
      splashRadius: 14,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText,
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText2,
        ),
      ),
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.ctText2,
            ),
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _FormField extends StatefulWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.hint,
    this.obscureText = false,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String? hint;
  final bool obscureText;

  @override
  State<_FormField> createState() => _FormFieldState();
}

class _FormFieldState extends State<_FormField> {
  bool _showText = false;

  @override
  Widget build(BuildContext context) {
    final isSecret = widget.obscureText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          obscureText: isSecret && !_showText,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.ctText,
          ),
          decoration: InputDecoration(
            hintText: widget.placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.ctText3,
            ),
            suffixIcon: isSecret
                ? IconButton(
                    icon: Icon(
                      _showText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 16,
                      color: AppColors.ctText3,
                    ),
                    onPressed: () =>
                        setState(() => _showText = !_showText),
                    splashRadius: 14,
                  )
                : null,
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
              borderSide:
                  const BorderSide(color: AppColors.ctTeal, width: 1.5),
            ),
          ),
        ),
        if (widget.hint != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.hint!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.ctText3,
            ),
          ),
        ],
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({
    required this.message,
    required this.isError,
  });
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg = isError ? AppColors.ctRedBg : AppColors.ctOkBg;
    final border =
        isError ? const Color(0xFFFECACA) : AppColors.ctOk;
    final textColor =
        isError ? AppColors.ctRedText : AppColors.ctOkText;
    final icon = isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_outline_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? AppColors.ctTeal.withValues(alpha: 0.5)
                : _hovered
                    ? AppColors.ctTealDark
                    : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.ctNavy),
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctNavy,
                  ),
                ),
        ),
      ),
    );
  }
}
