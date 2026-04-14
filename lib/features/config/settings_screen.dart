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

class _SettingsBody extends ConsumerWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TenantInfoSection(),
        SizedBox(height: 22),
        _UsersSection(),
      ],
    );
  }
}

// ── Sección: Información del tenant ──────────────────────────────────────────

class _TenantInfoSection extends ConsumerStatefulWidget {
  const _TenantInfoSection();

  @override
  ConsumerState<_TenantInfoSection> createState() =>
      _TenantInfoSectionState();
}

class _TenantInfoSectionState extends ConsumerState<_TenantInfoSection> {
  final _nameCtrl = TextEditingController();
  final _legalCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _loaded = false;
  String? _error;
  String? _success;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = ref.read(activeTenantIdProvider);
    if (!_loaded && tenantId.isNotEmpty) {
      _loaded = true;
      _loadTenant();
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _legalCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTenant() async {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.get('/tenants/$tenantId');
      final data = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      _nameCtrl.text = data['display_name']?.toString() ??
          data['name']?.toString() ??
          '';
      _legalCtrl.text = data['legal_name']?.toString() ?? '';
      _addressCtrl.text = data['address']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar datos del tenant: $e'),
          backgroundColor: AppColors.ctNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _save() async {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) return;

    setState(() {
      _saving = true;
      _error = null;
      _success = null;
    });

    try {
      await ApiClient.instance.put(
        '/tenants/$tenantId',
        data: {
          'display_name': _nameCtrl.text.trim(),
          'legal_name': _legalCtrl.text.trim(),
          'address': _addressCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _success = 'Información guardada correctamente';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _saving = false;
        _error = detail ?? 'Error al guardar la información';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Información del tenant',
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.ctTeal),
              ),
            )
          : Column(
              children: [
                _Field(
                  label: 'Nombre comercial',
                  controller: _nameCtrl,
                  placeholder: 'Ej: Mi Empresa',
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'Nombre legal',
                  controller: _legalCtrl,
                  placeholder: 'Razón social completa',
                ),
                const SizedBox(height: 14),
                _Field(
                  label: 'Dirección',
                  controller: _addressCtrl,
                  placeholder: 'Calle, ciudad, país',
                ),
                const SizedBox(height: 20),
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
                  child: _PrimaryButton(
                    label: 'Guardar',
                    loading: _saving,
                    onTap: _saving ? null : _save,
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Sección: Usuarios ─────────────────────────────────────────────────────────

class _UsersSection extends ConsumerStatefulWidget {
  const _UsersSection();

  @override
  ConsumerState<_UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<_UsersSection> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tenantId = ref.read(activeTenantIdProvider);
    if (!_loaded && tenantId.isNotEmpty) {
      _loaded = true;
      _loadUsers();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.get(
        '/iam/users',
        queryParameters: {'tenant_id': tenantId},
      );
      if (!mounted) return;
      final data = res.data;
      final List raw = data is List
          ? data
          : (data['users'] ?? data['items'] ?? []) as List;
      setState(() {
        _users = raw
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar usuarios: $e';
        _loading = false;
      });
    }
  }

  void _showInviteModal() {
    showDialog(
      context: context,
      builder: (_) => _InviteUserDialog(
        onInvited: _loadUsers,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Usuarios',
      trailing: _SmallButton(
        label: '+ Invitar usuario',
        onTap: _showInviteModal,
      ),
      child: _loading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.ctTeal),
              ),
            )
          : _error != null
              ? _FeedbackBanner(message: _error!, isError: true)
              : _users.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
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
                      users: _users,
                      onRefresh: _loadUsers,
                    ),
    );
  }
}

// ── Tabla de usuarios ─────────────────────────────────────────────────────────

class _UsersTable extends ConsumerWidget {
  const _UsersTable({
    required this.users,
    required this.onRefresh,
  });
  final List<Map<String, dynamic>> users;
  final VoidCallback onRefresh;

  static const _headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.ctText2,
    letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(7),
                topRight: Radius.circular(7),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('USUARIO', style: _headerStyle)),
                Expanded(flex: 2, child: Text('ROL', style: _headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: _headerStyle)),
                Expanded(flex: 2, child: Text('ALTA', style: _headerStyle)),
                Expanded(flex: 2, child: Text('ACCIONES', style: _headerStyle)),
              ],
            ),
          ),
          // Rows
          ...users.asMap().entries.map((entry) {
            final i = entry.key;
            final u = entry.value;
            final isLast = i == users.length - 1;
            return Column(
              children: [
                if (i > 0)
                  const Divider(height: 1, color: AppColors.ctBorder),
                _UserRow(
                  user: u,
                  isLast: isLast,
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

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({
    required this.user,
    required this.isLast,
    required this.onRefresh,
  });
  final Map<String, dynamic> user;
  final bool isLast;
  final VoidCallback onRefresh;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _hovered = false;
  bool _acting = false;

  String get _name =>
      widget.user['name']?.toString() ??
      widget.user['display_name']?.toString() ??
      '';
  String get _email => widget.user['email']?.toString() ?? '';
  String get _role => widget.user['role']?.toString() ?? '—';
  String get _status => widget.user['status']?.toString() ?? 'active';
  String get _createdAt {
    final raw = widget.user['created_at']?.toString() ?? '';
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  bool get _isActive => _status == 'active';

  Future<void> _toggleStatus() async {
    final userId = widget.user['id']?.toString() ?? '';
    final tenantId = ref.read(activeTenantIdProvider);
    if (userId.isEmpty) return;
    setState(() => _acting = true);
    try {
      final newStatus = _isActive ? 'suspended' : 'active';
      await ApiClient.instance.patch(
        '/iam/users/$userId',
        data: {'status': newStatus, 'tenant_id': tenantId},
      );
      widget.onRefresh();
    } catch (_) {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.isLast
        ? const BorderRadius.only(
            bottomLeft: Radius.circular(7),
            bottomRight: Radius.circular(7),
          )
        : BorderRadius.zero;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
          borderRadius: radius,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Usuario (nombre + email)
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
            // Rol
            Expanded(
              flex: 2,
              child: Text(
                _role,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
              ),
            ),
            // Status
            Expanded(
              flex: 2,
              child: _StatusBadge(status: _status),
            ),
            // Alta
            Expanded(
              flex: 2,
              child: Text(
                _createdAt,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            ),
            // Acciones
            Expanded(
              flex: 2,
              child: _acting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.ctTeal,
                      ),
                    )
                  : _GhostButton(
                      label: _isActive ? 'Suspender' : 'Reactivar',
                      color: _isActive
                          ? AppColors.ctDanger
                          : AppColors.ctOk,
                      onTap: _toggleStatus,
                    ),
            ),
          ],
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
    final isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.ctOkBg : AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Activo' : 'Suspendido',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.ctOkText : AppColors.ctText2,
        ),
      ),
    );
  }
}

// ── Modal invitar usuario ─────────────────────────────────────────────────────

class _InviteUserDialog extends ConsumerStatefulWidget {
  const _InviteUserDialog({required this.onInvited});
  final VoidCallback onInvited;

  @override
  ConsumerState<_InviteUserDialog> createState() =>
      _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<_InviteUserDialog> {
  final _emailCtrl = TextEditingController();
  String _role = 'operator';
  bool _sending = false;
  String? _error;

  static const _roles = ['operator', 'supervisor', 'admin'];

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Ingresa un email');
      return;
    }
    final tenantId = ref.read(activeTenantIdProvider);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ApiClient.instance.post(
        '/iam/invite',
        data: {
          'email': email,
          'role': _role,
          'tenant_id': tenantId,
        },
      );
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
        _error = detail ?? 'Error al enviar la invitación';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = 'Error: $e';
      });
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

              // Email
              _Field(
                label: 'Email',
                controller: _emailCtrl,
                placeholder: 'usuario@empresa.com',
              ),
              const SizedBox(height: 14),

              // Rol
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
                    value: _role,
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
                    items: _roles
                        .map((r) => DropdownMenuItem(
                              value: r,
                              child: Text(r),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _role = v);
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

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.title,
    required this.child,
    this.trailing,
  });
  final String title;
  final Widget child;
  final Widget? trailing;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.placeholder,
  });
  final String label;
  final TextEditingController controller;
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
          controller: controller,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: AppColors.ctText,
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
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
              borderSide:
                  const BorderSide(color: AppColors.ctTeal, width: 1.5),
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
    final bg = isError ? AppColors.ctRedBg : AppColors.ctOkBg;
    final border = isError ? const Color(0xFFFECACA) : AppColors.ctOk;
    final textColor = isError ? AppColors.ctRedText : AppColors.ctOkText;
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

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.loading = false,
  });
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
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
              : Text(
                  widget.label,
                  style: const TextStyle(
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
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter',
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
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
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

class _GhostButton extends StatefulWidget {
  const _GhostButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
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
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.4)
                  : AppColors.ctBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _hovered ? widget.color : AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}
