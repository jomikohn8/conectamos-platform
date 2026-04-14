import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
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
        return const _PlaceholderTab(
          icon: Icons.waving_hand_rounded,
          title: 'Próximamente',
          subtitle: 'Configura el mensaje de bienvenida automático',
        );
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
                SizedBox(width: 36),
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

  List<String> get _variables {
    final v = widget.template['variables'];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
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
              child: _variables.isEmpty
                  ? const Text(
                      '—',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.ctText3),
                    )
                  : Text(
                      _variables.join(', '),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.ctText2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
            ),

            // Status badge
            Expanded(
              flex: 2,
              child: _TemplateBadge(status: _status),
            ),

            // Acción eliminar
            SizedBox(
              width: 36,
              child: _deleting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ctTeal,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 16, color: AppColors.ctText3),
                      splashRadius: 14,
                      tooltip: 'Eliminar plantilla',
                      onPressed: _delete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
  String type; // 'system' | 'free'
  String key;
  _VarConfig({required this.type, required this.key});
}

// ── Modal nueva plantilla ─────────────────────────────────────────────────────

class _NewTemplateDialog extends StatefulWidget {
  const _NewTemplateDialog({
    required this.tenantId,
    required this.onCreated,
  });
  final String tenantId;
  final VoidCallback onCreated;

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

  int _countVars(String body) {
    final matches = RegExp(r'\{\{(\d+)\}\}').allMatches(body);
    if (matches.isEmpty) return 0;
    return matches
        .map((m) => int.tryParse(m.group(1) ?? '0') ?? 0)
        .reduce((a, b) => a > b ? a : b);
  }

  String _buildPreview() {
    String preview = _bodyCtrl.text;
    for (int i = 0; i < _varConfigs.length; i++) {
      final cfg = _varConfigs[i];
      String val;
      if (cfg.type == 'system') {
        val = _sysVarExample[cfg.key] ?? '{{${i + 1}}}';
      } else {
        final freeKey = _freeKeyCtrls[i].text.trim();
        val = freeKey.isNotEmpty ? '[$freeKey]' : '{{${i + 1}}}';
      }
      preview = preview.replaceAll('{{${i + 1}}}', val);
    }
    return preview;
  }

  void _syncVarsFromBody() {
    final count = _countVars(_bodyCtrl.text);
    if (count == _varConfigs.length) return;
    setState(() {
      while (_varConfigs.length < count) {
        _varConfigs.add(_VarConfig(
          type: 'system',
          key:  _sysVarDesc.keys.first,
        ));
        final ctrl = TextEditingController();
        ctrl.addListener(() => setState(() {}));
        _freeKeyCtrls.add(ctrl);
      }
      while (_varConfigs.length > count) {
        _varConfigs.removeLast();
        _freeKeyCtrls.last.dispose();
        _freeKeyCtrls.removeLast();
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
      await ApiClient.instance.post('/templates', data: {
        'tenant_id':  widget.tenantId,
        'name':       name,
        'category':   _category,
        'language':   _language,
        'body_text':  body,
        'variables':  List.generate(_varConfigs.length, (i) {
          final cfg = _varConfigs[i];
          return {
            'slot': i + 1,
            'type': cfg.type,
            'key':  cfg.type == 'system'
                ? cfg.key
                : _freeKeyCtrls[i].text.trim(),
          };
        }),
        'is_welcome': false,
      });
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
                  'Variable {{${i + 1}}}',
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
              child: const Row(
                children: [
                  Text(
                    'Nueva plantilla',
                    style: TextStyle(
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

// ── Tab placeholder ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 26, color: AppColors.ctText3),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.ctText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: AppColors.ctText2,
            ),
          ),
        ],
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
