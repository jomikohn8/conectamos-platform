import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Pantalla ──────────────────────────────────────────────────────────────────

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        _ActionBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(22),
            child: _SettingsBody(),
          ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar();

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
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ajustes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Configuración general del tenant',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.ctText2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Cuerpo ────────────────────────────────────────────────────────────────────

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GeneralInfoCard(),
        SizedBox(height: 20),
        _AddressCard(),
        SizedBox(height: 20),
        _BillingCard(),
        SizedBox(height: 20),
        _UsersCard(),
      ],
    );
  }
}

// ── Sección 1 — Información general ──────────────────────────────────────────

class _GeneralInfoCard extends ConsumerStatefulWidget {
  const _GeneralInfoCard();

  @override
  ConsumerState<_GeneralInfoCard> createState() => _GeneralInfoCardState();
}

class _GeneralInfoCardState extends ConsumerState<_GeneralInfoCard> {
  final _displayNameCtrl = TextEditingController();
  final _legalNameCtrl   = TextEditingController();
  final _rfcCtrl         = TextEditingController();
  final _emailCtrl       = TextEditingController();
  final _telefonoCtrl    = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  String _currentTenantId = '';
  String? _error;
  String? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isNotEmpty && tenantId != _currentTenantId) {
      _currentTenantId = tenantId;
      _load();
    }
  }

  @override
  void dispose() {
    _displayNameCtrl.dispose();
    _legalNameCtrl.dispose();
    _rfcCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get('/tenants/$_currentTenantId');
      final d = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      _displayNameCtrl.text = d['display_name']?.toString() ?? d['name']?.toString() ?? '';
      _legalNameCtrl.text   = d['legal_name']?.toString() ?? '';
      _rfcCtrl.text         = d['rfc']?.toString() ?? '';
      _emailCtrl.text       = d['email_contacto']?.toString() ?? '';
      _telefonoCtrl.text    = d['telefono']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Error al cargar: $e'));
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiClient.instance.put('/tenants/$_currentTenantId', data: {
        'display_name':   _displayNameCtrl.text.trim(),
        'legal_name':     _legalNameCtrl.text.trim(),
        'rfc':            _rfcCtrl.text.trim(),
        'email_contacto': _emailCtrl.text.trim(),
        'telefono':       _telefonoCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _saving = false; _success = 'Información guardada'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = msg ?? 'Error al guardar'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Información general',
      loading: _loading,
      error: _error,
      success: _success,
      onSave: _saving ? null : _save,
      saving: _saving,
      child: Column(
        children: [
          _Row2(
            left: _Field(label: 'Nombre comercial', ctrl: _displayNameCtrl, placeholder: 'Ej: Mi Empresa'),
            right: _Field(label: 'Razón social', ctrl: _legalNameCtrl, placeholder: 'Nombre legal completo'),
          ),
          const SizedBox(height: 14),
          _Row2(
            left: _Field(label: 'RFC', ctrl: _rfcCtrl, placeholder: 'XAXX010101000'),
            right: _Field(label: 'Teléfono', ctrl: _telefonoCtrl, placeholder: '+52 55 1234 5678'),
          ),
          const SizedBox(height: 14),
          _Field(label: 'Email de contacto', ctrl: _emailCtrl, placeholder: 'contacto@empresa.com'),
        ],
      ),
    );
  }
}

// ── Sección 2 — Dirección ─────────────────────────────────────────────────────

class _AddressCard extends ConsumerStatefulWidget {
  const _AddressCard();

  @override
  ConsumerState<_AddressCard> createState() => _AddressCardState();
}

class _AddressCardState extends ConsumerState<_AddressCard> {
  final _calleCtrl   = TextEditingController();
  final _numExtCtrl  = TextEditingController();
  final _numIntCtrl  = TextEditingController();
  final _coloniaCtrl = TextEditingController();
  final _ciudadCtrl  = TextEditingController();
  final _estadoCtrl  = TextEditingController();
  final _cpCtrl      = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  String _currentTenantId = '';
  String? _error;
  String? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isNotEmpty && tenantId != _currentTenantId) {
      _currentTenantId = tenantId;
      _load();
    }
  }

  @override
  void dispose() {
    _calleCtrl.dispose();
    _numExtCtrl.dispose();
    _numIntCtrl.dispose();
    _coloniaCtrl.dispose();
    _ciudadCtrl.dispose();
    _estadoCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get('/tenants/$_currentTenantId');
      final d = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      _calleCtrl.text   = d['calle']?.toString() ?? '';
      _numExtCtrl.text  = d['numero_exterior']?.toString() ?? '';
      _numIntCtrl.text  = d['numero_interior']?.toString() ?? '';
      _coloniaCtrl.text = d['colonia']?.toString() ?? '';
      _ciudadCtrl.text  = d['ciudad']?.toString() ?? '';
      _estadoCtrl.text  = d['estado_cliente']?.toString() ?? '';
      _cpCtrl.text      = d['codigo_postal']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Error al cargar: $e'));
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiClient.instance.put('/tenants/$_currentTenantId', data: {
        'calle':           _calleCtrl.text.trim(),
        'numero_exterior': _numExtCtrl.text.trim(),
        'numero_interior': _numIntCtrl.text.trim(),
        'colonia':         _coloniaCtrl.text.trim(),
        'ciudad':          _ciudadCtrl.text.trim(),
        'estado_cliente':  _estadoCtrl.text.trim(),
        'codigo_postal':   _cpCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _saving = false; _success = 'Dirección guardada'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = msg ?? 'Error al guardar'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Dirección',
      loading: _loading,
      error: _error,
      success: _success,
      onSave: _saving ? null : _save,
      saving: _saving,
      child: Column(
        children: [
          _Row2(
            left: _Field(label: 'Calle', ctrl: _calleCtrl, placeholder: 'Nombre de la calle'),
            right: _Row2(
              left: _Field(label: 'Núm. exterior', ctrl: _numExtCtrl, placeholder: '123'),
              right: _Field(label: 'Núm. interior', ctrl: _numIntCtrl, placeholder: 'Opcional'),
            ),
          ),
          const SizedBox(height: 14),
          _Row2(
            left: _Field(label: 'Colonia', ctrl: _coloniaCtrl, placeholder: 'Col. Centro'),
            right: _Field(label: 'Ciudad', ctrl: _ciudadCtrl, placeholder: 'Ciudad de México'),
          ),
          const SizedBox(height: 14),
          _Row2(
            left: _Field(label: 'Estado', ctrl: _estadoCtrl, placeholder: 'CDMX'),
            right: _Field(label: 'Código postal', ctrl: _cpCtrl, placeholder: '06600'),
          ),
        ],
      ),
    );
  }
}

// ── Sección 3 — Facturación ───────────────────────────────────────────────────

class _BillingCard extends ConsumerStatefulWidget {
  const _BillingCard();

  @override
  ConsumerState<_BillingCard> createState() => _BillingCardState();
}

class _BillingCardState extends ConsumerState<_BillingCard> {
  final _regimenCtrl = TextEditingController();
  final _usoCfdiCtrl = TextEditingController();

  bool _loading = true;
  bool _saving  = false;
  bool _requiereCfdi = false;
  String _currentTenantId = '';
  String? _error;
  String? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isNotEmpty && tenantId != _currentTenantId) {
      _currentTenantId = tenantId;
      _load();
    }
  }

  @override
  void dispose() {
    _regimenCtrl.dispose();
    _usoCfdiCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient.instance.get('/tenants/$_currentTenantId');
      final d = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      _requiereCfdi     = d['requiere_cfdi'] == true;
      _regimenCtrl.text = d['regimen_fiscal']?.toString() ?? '';
      _usoCfdiCtrl.text = d['uso_cfdi']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(_errorSnack('Error al cargar: $e'));
    }
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; _success = null; });
    try {
      await ApiClient.instance.put('/tenants/$_currentTenantId', data: {
        'requiere_cfdi':  _requiereCfdi,
        'regimen_fiscal': _regimenCtrl.text.trim(),
        'uso_cfdi':       _usoCfdiCtrl.text.trim(),
      });
      if (!mounted) return;
      setState(() { _saving = false; _success = 'Facturación guardada'; });
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = msg ?? 'Error al guardar'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Facturación',
      loading: _loading,
      error: _error,
      success: _success,
      onSave: _saving ? null : _save,
      saving: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '¿Requiere CFDI?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _requiereCfdi ? 'Sí, requiere factura' : 'No requiere factura',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _requiereCfdi,
                onChanged: (v) => setState(() => _requiereCfdi = v),
                activeThumbColor: AppColors.ctTeal,
              ),
            ],
          ),
          if (_requiereCfdi) ...[
            const SizedBox(height: 16),
            _Row2(
              left: _Field(
                label: 'Régimen fiscal',
                ctrl: _regimenCtrl,
                placeholder: 'Ej: 601 - General de Ley',
              ),
              right: _Field(
                label: 'Uso de CFDI',
                ctrl: _usoCfdiCtrl,
                placeholder: 'Ej: G03 - Gastos en general',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── FutureProvider para usuarios ──────────────────────────────────────────────

final _usersListProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return [];
    final res = await ApiClient.instance.get(
      '/iam/users',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = res.data;
    final List raw = data is List
        ? data
        : (data['users'] ?? data['items'] ?? []) as List;
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  },
);

// ── Sección 4 — Usuarios ──────────────────────────────────────────────────────

class _UsersCard extends ConsumerWidget {
  const _UsersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId   = ref.watch(activeTenantIdProvider);
    final usersAsync = ref.watch(_usersListProvider(tenantId));

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Usuarios',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
              ),
              _SmallButton(
                label: '+ Invitar usuario',
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => _InviteUserDialog(
                    tenantId: tenantId,
                    onInvited: () =>
                        ref.invalidate(_usersListProvider(tenantId)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          usersAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.ctTeal),
              ),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FeedbackBanner(
                  message: 'Error al cargar usuarios: $e',
                  isError: true,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(_usersListProvider(tenantId)),
                  child: const Text(
                    'Reintentar',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctTeal,
                    ),
                  ),
                ),
              ],
            ),
            data: (users) => users.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No hay usuarios registrados en este tenant.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.ctText2,
                      ),
                    ),
                  )
                : _UsersTable(
                    users: users,
                    tenantId: tenantId,
                    onRefresh: () =>
                        ref.invalidate(_usersListProvider(tenantId)),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Tabla de usuarios ─────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  const _UsersTable({
    required this.users,
    required this.tenantId,
    required this.onRefresh,
  });
  final List<Map<String, dynamic>> users;
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
          // Header
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
                Expanded(flex: 3, child: Text('USUARIO', style: _h)),
                Expanded(flex: 2, child: Text('TELÉFONO', style: _h)),
                Expanded(flex: 2, child: Text('ROL', style: _h)),
                Expanded(flex: 2, child: Text('STATUS', style: _h)),
                SizedBox(width: 36),
              ],
            ),
          ),
          // Rows
          ...users.asMap().entries.map((entry) {
            final i = entry.key;
            final u = entry.value;
            return Column(
              children: [
                if (i > 0) const Divider(height: 1, color: AppColors.ctBorder),
                _UserRow(
                  user: u,
                  tenantId: tenantId,
                  isLast: i == users.length - 1,
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

// ── Fila de usuario ───────────────────────────────────────────────────────────

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({
    required this.user,
    required this.tenantId,
    required this.isLast,
    required this.onRefresh,
  });
  final Map<String, dynamic> user;
  final String tenantId;
  final bool isLast;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _hovered = false;
  bool _acting  = false;

  String get _id => widget.user['id']?.toString() ?? '';
  String get _name =>
      widget.user['name']?.toString() ??
      widget.user['nombre']?.toString() ??
      widget.user['display_name']?.toString() ?? '';
  String get _email =>
      widget.user['email']?.toString() ??
      widget.user['user_email']?.toString() ?? '';
  String get _phone =>
      widget.user['phone']?.toString() ??
      widget.user['telefono']?.toString() ??
      widget.user['phone_number']?.toString() ?? '';
  String get _role =>
      widget.user['role']?.toString() ??
      widget.user['role_name']?.toString() ?? '';
  String get _status => widget.user['status']?.toString() ?? 'active';

  Future<void> _patch(Map<String, dynamic> body) async {
    if (_id.isEmpty) return;
    setState(() => _acting = true);
    try {
      await ApiClient.instance.patch('/iam/users/$_id', data: body);
      widget.onRefresh();
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _resendInvitation() async {
    if (_id.isEmpty) return;
    setState(() => _acting = true);
    try {
      await ApiClient.instance.post(
        '/iam/users/$_id/resend-invite',
        data: {'tenant_id': widget.tenantId},
      );
      if (mounted) setState(() => _acting = false);
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  void _showChangeRoleDialog() {
    showDialog(
      context: context,
      builder: (_) => _ChangeRoleDialog(
        userId: _id,
        tenantId: widget.tenantId,
        onChanged: widget.onRefresh,
      ),
    );
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
            // Usuario
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_name.isNotEmpty)
                    Text(
                      _name,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctText,
                      ),
                    ),
                  Text(
                    _email,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: _name.isNotEmpty ? 11 : 13,
                      color: _name.isNotEmpty
                          ? AppColors.ctText2
                          : AppColors.ctText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Teléfono
            Expanded(
              flex: 2,
              child: Text(
                _phone.isNotEmpty ? _phone : '—',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            ),

            // Rol
            Expanded(
              flex: 2,
              child: _RoleBadge(role: _role),
            ),

            // Status
            Expanded(
              flex: 2,
              child: _StatusBadge(status: _status),
            ),

            // Acciones
            SizedBox(
              width: 36,
              child: _acting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ctTeal,
                      ),
                    )
                  : PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.ctText3,
                      ),
                      color: AppColors.ctSurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: const BorderSide(color: AppColors.ctBorder),
                      ),
                      itemBuilder: (_) {
                        final items = <PopupMenuEntry<String>>[];
                        if (_status == 'active') {
                          items.add(const PopupMenuItem(
                            value: 'suspend',
                            child: Text(
                              'Suspender',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                              ),
                            ),
                          ));
                        } else if (_status == 'suspended') {
                          items.add(const PopupMenuItem(
                            value: 'reactivate',
                            child: Text(
                              'Reactivar',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                              ),
                            ),
                          ));
                        } else if (_status == 'invited') {
                          items.add(const PopupMenuItem(
                            value: 'resend',
                            child: Text(
                              'Reenviar invitación',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                              ),
                            ),
                          ));
                        }
                        items.add(const PopupMenuItem(
                          value: 'role',
                          child: Text(
                            'Cambiar rol',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                            ),
                          ),
                        ));
                        return items;
                      },
                      onSelected: (v) {
                        if (v == 'suspend') {
                          _patch({
                            'status': 'suspended',
                            'tenant_id': widget.tenantId,
                          });
                        } else if (v == 'reactivate') {
                          _patch({
                            'status': 'active',
                            'tenant_id': widget.tenantId,
                          });
                        } else if (v == 'resend') {
                          _resendInvitation();
                        } else if (v == 'role') {
                          _showChangeRoleDialog();
                        }
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Badges ────────────────────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    if (role.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Text(
        role,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.ctText2,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color textColor;
    final String label;

    if (status == 'invited') {
      bg        = const Color(0xFFFEF3C7);
      textColor = const Color(0xFF92400E);
      label     = 'Invitado';
    } else if (status == 'suspended') {
      bg        = AppColors.ctRedBg;
      textColor = AppColors.ctRedText;
      label     = 'Suspendido';
    } else {
      bg        = AppColors.ctOkBg;
      textColor = AppColors.ctOkText;
      label     = 'Activo';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// ── Dialog: Cambiar rol ───────────────────────────────────────────────────────

class _ChangeRoleDialog extends ConsumerStatefulWidget {
  const _ChangeRoleDialog({
    required this.userId,
    required this.tenantId,
    required this.onChanged,
  });
  final String userId;
  final String tenantId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_ChangeRoleDialog> createState() => _ChangeRoleDialogState();
}

class _ChangeRoleDialogState extends ConsumerState<_ChangeRoleDialog> {
  List<Map<String, dynamic>> _roles = [];
  String? _roleId;
  bool _rolesLoading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final res = await ApiClient.instance.get(
        '/iam/roles',
        queryParameters: {'tenant_id': widget.tenantId},
      );
      if (!mounted) return;
      final data = res.data;
      final List raw = data is List
          ? data
          : (data['roles'] ?? data['items'] ?? []) as List;
      final roles =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _roles       = roles;
        _roleId      = roles.isNotEmpty ? roles.first['id']?.toString() : null;
        _rolesLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  Future<void> _save() async {
    if (_roleId == null || _roleId!.isEmpty) return;
    setState(() { _saving = true; _error = null; });
    try {
      await ApiClient.instance.patch(
        '/iam/users/${widget.userId}/role',
        data: {'role_id': _roleId},
      );
      if (!mounted) return;
      widget.onChanged();
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() { _saving = false; _error = detail ?? 'Error al cambiar rol'; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _error = 'Error: $e'; });
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
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cambiar rol',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 16),
              if (_rolesLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppColors.ctTeal),
                  ),
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
                    child: DropdownButton<String>(
                      value: _roles.any(
                              (r) => r['id']?.toString() == _roleId)
                          ? _roleId
                          : null,
                      isExpanded: true,
                      isDense: true,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.ctText,
                      ),
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: AppColors.ctText3,
                      ),
                      items: _roles.map((r) {
                        final id   = r['id']?.toString() ?? '';
                        final name = r['name']?.toString() ?? id;
                        return DropdownMenuItem<String>(
                          value: id,
                          child: Text(name),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _roleId = v);
                      },
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _FeedbackBanner(message: _error!, isError: true),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _OutlineButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _PrimaryButton(
                    label: 'Guardar',
                    loading: _saving,
                    onTap: (_saving || _rolesLoading) ? null : _save,
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

// ── Modal invitar usuario ─────────────────────────────────────────────────────

class _InviteUserDialog extends ConsumerStatefulWidget {
  const _InviteUserDialog({required this.tenantId, required this.onInvited});
  final String tenantId;
  final VoidCallback onInvited;

  @override
  ConsumerState<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<_InviteUserDialog> {
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  List<Map<String, dynamic>> _availableRoles = [];
  String? _roleId;
  bool _rolesLoading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    try {
      final res = await ApiClient.instance.get(
        '/iam/roles',
        queryParameters: {'tenant_id': widget.tenantId},
      );
      if (!mounted) return;
      final data = res.data;
      final List raw = data is List
          ? data
          : (data['roles'] ?? data['items'] ?? []) as List;
      final roles =
          raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _availableRoles = roles;
        _roleId         = roles.isNotEmpty ? roles.first['id']?.toString() : null;
        _rolesLoading   = false;
      });
    } catch (_) {
      if (mounted) setState(() => _rolesLoading = false);
    }
  }

  Future<void> _send() async {
    final nombre = _nombreCtrl.text.trim();
    final email  = _emailCtrl.text.trim();
    if (nombre.isEmpty) {
      setState(() => _error = 'Ingresa el nombre completo');
      return;
    }
    if (email.isEmpty) {
      setState(() => _error = 'Ingresa un email');
      return;
    }
    if (_roleId == null || _roleId!.isEmpty) {
      setState(() => _error = 'Selecciona un rol');
      return;
    }
    setState(() { _sending = true; _error = null; });
    try {
      await ApiClient.instance.post('/iam/invite', data: {
        'nombre':    nombre,
        'telefono':  _telefonoCtrl.text.trim(),
        'email':     email,
        'role_id':   _roleId,
        'tenant_id': widget.tenantId,
      });
      if (!mounted) return;
      widget.onInvited();
      Navigator.pop(context);
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _sending = false;
        _error   = detail ?? 'Error al enviar la invitación';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _error = 'Error: $e'; });
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
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Invitar usuario',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),
              _Field(
                label: 'Nombre completo',
                ctrl: _nombreCtrl,
                placeholder: 'Juan García',
              ),
              const SizedBox(height: 12),
              _Row2(
                left: _Field(
                  label: 'Email',
                  ctrl: _emailCtrl,
                  placeholder: 'usuario@empresa.com',
                ),
                right: _Field(
                  label: 'Teléfono (opcional)',
                  ctrl: _telefonoCtrl,
                  placeholder: '+52 55 1234 5678',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rol',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              _rolesLoading
                  ? const SizedBox(
                      height: 40,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.ctTeal,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ctBorder2),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _availableRoles.any(
                                  (r) => r['id']?.toString() == _roleId)
                              ? _roleId
                              : null,
                          isExpanded: true,
                          isDense: true,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 16,
                            color: AppColors.ctText3,
                          ),
                          items: _availableRoles.map((r) {
                            final id   = r['id']?.toString() ?? '';
                            final name = r['name']?.toString() ?? id;
                            return DropdownMenuItem<String>(
                              value: id,
                              child: Text(name),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _roleId = v);
                          },
                        ),
                      ),
                    ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _FeedbackBanner(message: _error!, isError: true),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _OutlineButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _PrimaryButton(
                    label: 'Enviar invitación',
                    loading: _sending,
                    onTap: _sending ? null : _send,
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

// ── Shared: SectionCard ───────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    required this.loading,
    required this.saving,
    required this.onSave,
    this.error,
    this.success,
  });
  final String title;
  final Widget child;
  final bool loading;
  final bool saving;
  final VoidCallback? onSave;
  final String? error;
  final String? success;

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
          const SizedBox(height: 16),
          if (loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.ctTeal),
              ),
            )
          else ...[
            child,
            const SizedBox(height: 20),
            if (error != null) ...[
              _FeedbackBanner(message: error!, isError: true),
              const SizedBox(height: 12),
            ],
            if (success != null) ...[
              _FeedbackBanner(message: success!, isError: false),
              const SizedBox(height: 12),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: _PrimaryButton(label: 'Guardar', loading: saving, onTap: onSave),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared: _Row2 (dos columnas iguales) ──────────────────────────────────────

class _Row2 extends StatelessWidget {
  const _Row2({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 14),
        Expanded(child: right),
      ],
    );
  }
}

// ── Shared: widgets reutilizables ─────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.ctrl,
    required this.placeholder,
  });
  final String label;
  final TextEditingController ctrl;
  final String placeholder;

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
        TextField(
          controller: ctrl,
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText3),
            filled: true,
            fillColor: AppColors.ctSurface2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          ),
        ),
      ],
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final bg        = isError ? AppColors.ctRedBg  : AppColors.ctOkBg;
    final border    = isError ? const Color(0xFFFECACA) : AppColors.ctOk;
    final textColor = isError ? AppColors.ctRedText : AppColors.ctOkText;
    final icon      = isError
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
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap, this.loading = false});
  final String label;
  final VoidCallback? onTap;
  final bool loading;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? AppColors.ctTeal.withValues(alpha: 0.5)
                : _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctNavy),
                  ),
                )
              : Text(
                  widget.label,
                  style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 13,
                    fontWeight: FontWeight.w600, color: AppColors.ctNavy,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
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
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 13,
              fontWeight: FontWeight.w500, color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatefulWidget {
  const _SmallButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<_SmallButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12,
              fontWeight: FontWeight.w600, color: AppColors.ctNavy,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helper global ─────────────────────────────────────────────────────────────

SnackBar _errorSnack(String msg) => SnackBar(
      content: Text(msg, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
      backgroundColor: AppColors.ctNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
    );
