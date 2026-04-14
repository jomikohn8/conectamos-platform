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
        return const _PlaceholderTab(
          icon: Icons.format_list_bulleted_rounded,
          title: 'Próximamente',
          subtitle: 'Gestión de plantillas aprobadas por Meta',
        );
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
      _loadCredentials();
    }
  }

  @override
  void dispose() {
    _phoneIdCtrl.dispose();
    _wabaIdCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCredentials() async {
    final tenantId = ref.read(activeTenantIdProvider);
    if (tenantId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await ApiClient.instance.get('/tenants/$tenantId');
      final data = Map<String, dynamic>.from(res.data as Map);
      if (!mounted) return;
      _phoneIdCtrl.text = data['wa_phone_number_id']?.toString() ?? '';
      _wabaIdCtrl.text = data['wa_waba_id']?.toString() ?? '';
      _tokenCtrl.text = data['wa_token']?.toString() ?? '';
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar credenciales: $e'),
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
      await ApiClient.instance.patch(
        '/tenants/$tenantId/credentials',
        data: {
          'wa_phone_number_id': _phoneIdCtrl.text.trim(),
          'wa_waba_id': _wabaIdCtrl.text.trim(),
          'wa_token': _tokenCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _success = 'Credenciales guardadas correctamente';
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _saving = false;
        _error = detail ?? 'Error al guardar las credenciales';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Error al guardar: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.ctTeal),
      );
    }

    return SingleChildScrollView(
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

                // Feedback
                if (_error != null) ...[
                  _FeedbackBanner(
                    message: _error!,
                    isError: true,
                  ),
                  const SizedBox(height: 12),
                ],
                if (_success != null) ...[
                  _FeedbackBanner(
                    message: _success!,
                    isError: false,
                  ),
                  const SizedBox(height: 12),
                ],

                // Botón guardar
                Align(
                  alignment: Alignment.centerRight,
                  child: _SaveButton(
                    loading: _saving,
                    onTap: _saving ? null : _save,
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
