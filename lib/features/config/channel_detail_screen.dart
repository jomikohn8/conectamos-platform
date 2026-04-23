import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/ai_workers_api.dart';
import '../../core/api/channels_api.dart';
import '../../core/api/operators_api.dart';
import '../../core/api/templates_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/colors.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kColorPalette = [
  '#2DD4BF', '#818CF8', '#FB923C', '#F472B6', '#34D399', '#60A5FA',
];

const _kChannelTypeConfig = {
  'whatsapp': (label: 'WhatsApp', bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF)),
  'telegram': (label: 'Telegram', bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9)),
  'sms':      (label: 'SMS',      bg: Color(0xFFFFEDD5), fg: Color(0xFFC2410C)),
};

const _kTemplateTabs = ['Información', 'Credenciales', 'Plantillas', 'Bienvenida'];
const _kInfoOnlyTabs = ['Información'];

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
    if (s != null) return 'Error $s';
  }
  return e.toString();
}

// ── Screen ────────────────────────────────────────────────────────────────────

class ChannelDetailScreen extends ConsumerStatefulWidget {
  const ChannelDetailScreen({super.key, required this.channelId});
  final String channelId;

  @override
  ConsumerState<ChannelDetailScreen> createState() =>
      _ChannelDetailScreenState();
}

class _ChannelDetailScreenState extends ConsumerState<ChannelDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _channel;
  List<Map<String, dynamic>> _workers   = [];
  List<Map<String, dynamic>> _operators = [];
  bool    _loading = true;
  String? _error;
  bool    _toggling = false;
  String  _tenantId = '';

  TabController? _tabCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      _tenantId = tenantId;
      final results = await Future.wait([
        ChannelsApi.getChannel(channelId: widget.channelId, tenantId: tenantId),
        AiWorkersApi.listWorkers(tenantId: tenantId),
        OperatorsApi.listOperators(tenantId: tenantId),
      ]);
      if (!mounted) return;
      final channel = results[0] as Map<String, dynamic>;
      final isWa = (channel['channel_type'] as String? ?? '') == 'whatsapp';
      final tabs = isWa ? _kTemplateTabs : _kInfoOnlyTabs;
      _tabCtrl?.dispose();
      _tabCtrl = TabController(length: tabs.length, vsync: this);
      setState(() {
        _channel   = channel;
        _workers   = List<Map<String, dynamic>>.from(results[1] as List);
        _operators = List<Map<String, dynamic>>.from(results[2] as List);
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = _dioError(e); _loading = false; });
    }
  }

  bool get _isWhatsApp =>
      (_channel?['channel_type'] as String? ?? '') == 'whatsapp';

  Future<void> _toggleActive() async {
    final ch = _channel;
    if (ch == null) return;
    final current = ch['is_active'] as bool? ?? false;
    setState(() => _toggling = true);
    try {
      if (current) {
        final updated = await ChannelsApi.updateChannel(
          channelId: widget.channelId,
          isActive: false,
          tenantId: _tenantId,
        );
        if (!mounted) return;
        setState(() { _channel = updated; _toggling = false; });
      } else {
        await ChannelsApi.activateChannel(
          channelId: widget.channelId,
          tenantId: _tenantId,
        );
        if (!mounted) return;
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _toggling = false);
      _showError(_dioError(e));
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13)),
        backgroundColor: AppColors.ctDanger,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            style: const TextStyle(fontFamily: 'Geist', fontSize: 13)),
        backgroundColor: AppColors.ctOk,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.ctBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(),
        body: Center(
          child: Text('Error: $_error',
              style: const TextStyle(
                  fontFamily: 'Geist', fontSize: 13, color: AppColors.ctDanger)),
        ),
      );
    }

    final ch = _channel!;
    final isActive = ch['is_active'] as bool? ?? true;
    final tabs = _isWhatsApp ? _kTemplateTabs : _kInfoOnlyTabs;

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // ── Header band ──
          Container(
            color: AppColors.ctSurface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Color dot
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _hexColor(ch['color'] as String?),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ch['display_name'] as String? ?? widget.channelId,
                        style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ctText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _TypeChip(ch['channel_type'] as String? ?? ''),
                          const SizedBox(width: 8),
                          _StatusChip(isActive),
                        ],
                      ),
                    ],
                  ),
                ),
                // Activar / Desactivar
                _toggling
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : _OutlineButton(
                        label: isActive ? 'Desactivar' : 'Activar',
                        danger: isActive,
                        onTap: _toggleActive,
                      ),
              ],
            ),
          ),

          // ── Tab bar ──
          Container(
            color: AppColors.ctSurface,
            child: Column(
              children: [
                const Divider(height: 1, color: AppColors.ctBorder),
                TabBar(
                  controller: _tabCtrl,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  labelStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  labelColor: AppColors.ctTeal,
                  unselectedLabelColor: AppColors.ctText2,
                  indicatorColor: AppColors.ctTeal,
                  indicatorWeight: 2,
                  tabs: [for (final t in tabs) Tab(text: t)],
                ),
              ],
            ),
          ),

          // ── Tab views ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _InfoTab(
                  channel: _channel!,
                  workers: _workers,
                  operators: _operators,
                  onUpdated: (updated) {
                    if (mounted) setState(() => _channel = updated);
                  },
                  onError: _showError,
                  onSuccess: _showSuccess,
                ),
                if (_isWhatsApp) ...[
                  _CredentialsTab(
                    channel: _channel!,
                    tenantId: _tenantId,
                    onUpdated: (updated) {
                      if (mounted) setState(() => _channel = updated);
                    },
                    onError: _showError,
                    onSuccess: _showSuccess,
                  ),
                  _TemplatesTab(
                    channelId: widget.channelId,
                    tenantId: _tenantId,
                    onError: _showError,
                    onSuccess: _showSuccess,
                  ),
                  _WelcomeTab(
                    channel: _channel!,
                    tenantId: _tenantId,
                    onError: _showError,
                    onSuccess: _showSuccess,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final name = _channel?['display_name'] as String? ?? widget.channelId;
    return AppBar(
      backgroundColor: AppColors.ctSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.ctText),
        onPressed: () => context.go('/channels'),
      ),
      title: Text(
        name,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText,
        ),
      ),
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppColors.ctBorder),
      ),
    );
  }
}

// ── TAB 1 — Información ───────────────────────────────────────────────────────

class _InfoTab extends StatefulWidget {
  const _InfoTab({
    required this.channel,
    required this.workers,
    required this.operators,
    required this.onUpdated,
    required this.onError,
    required this.onSuccess,
  });
  final Map<String, dynamic> channel;
  final List<Map<String, dynamic>> workers;
  final List<Map<String, dynamic>> operators;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  final ValueChanged<String> onError;
  final ValueChanged<String> onSuccess;

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  late final TextEditingController _nameCtrl;
  late String _selectedColor;
  late String? _selectedWorkerId;
  bool _saving = false;

  List<Map<String, dynamic>> get _assignedOps {
    final opIds = (widget.channel['operator_ids'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toSet();
    if (opIds.isEmpty) return [];
    return widget.operators.where((o) => opIds.contains(o['id'])).toList();
  }


  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
        text: widget.channel['display_name'] as String? ?? '');
    _selectedColor = widget.channel['color'] as String? ?? _kColorPalette[0];
    _selectedWorkerId = widget.channel['tenant_worker_id'] as String?;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      final updated = await ChannelsApi.updateChannel(
        channelId: widget.channel['id'] as String,
        displayName: name,
        color: _selectedColor,
        tenantWorkerId: _selectedWorkerId,
        tenantId: widget.channel['tenant_id'] as String?,
      );
      widget.onUpdated(updated);
      widget.onSuccess('Cambios guardados');
    } catch (e) {
      widget.onError(_dioError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Información del canal',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Nombre del canal'),
                const SizedBox(height: 6),
                _StyledTextField(controller: _nameCtrl, hint: 'Mi canal'),
                const SizedBox(height: 16),
                _FieldLabel('Worker IA asignado'),
                const SizedBox(height: 6),
                _WorkerDropdown(
                  workers: widget.workers,
                  value: _selectedWorkerId,
                  onChanged: (v) => setState(() => _selectedWorkerId = v),
                ),
                const SizedBox(height: 16),
                _FieldLabel('Color del canal'),
                const SizedBox(height: 8),
                _ColorPicker(
                  selected: _selectedColor,
                  onChanged: (c) => setState(() => _selectedColor = c),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: _PrimaryButton(
                    label: 'Guardar cambios',
                    loading: _saving,
                    onTap: _save,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionCard(
            title: 'Operadores asignados',
            child: _assignedOps.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'Sin operadores asignados.',
                      style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.ctText2),
                    ),
                  )
                : Column(
                    children: [
                      for (final op in _assignedOps)
                        _OperatorRow(op: op),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ── TAB 2 — Credenciales ──────────────────────────────────────────────────────

class _CredentialsTab extends StatefulWidget {
  const _CredentialsTab({
    required this.channel,
    required this.tenantId,
    required this.onUpdated,
    required this.onError,
    required this.onSuccess,
  });
  final Map<String, dynamic> channel;
  final String tenantId;
  final ValueChanged<Map<String, dynamic>> onUpdated;
  final ValueChanged<String> onError;
  final ValueChanged<String> onSuccess;

  @override
  State<_CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends State<_CredentialsTab> {
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _wabaCtrl;
  late final TextEditingController _tokenCtrl;
  late final TextEditingController _pinCtrl;
  late final TextEditingController _pinConfirmCtrl;
  bool    _saving             = false;
  bool    _verifying          = false;
  String? _verifyError;
  bool    _showToken          = false;
  bool    _showPin            = false;
  bool    _showPinConfirm     = false;
  bool    _credentialsLocked  = false;

  Map<String, dynamic> get _credentials {
    final cfg = widget.channel['channel_config'];
    if (cfg is Map) {
      final creds = cfg['credentials'];
      if (creds is Map) return Map<String, dynamic>.from(creds);
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    final creds = _credentials;
    _phoneCtrl = TextEditingController(
        text: widget.channel['phone_number_id'] as String?
            ?? creds['phone_number_id'] as String? ?? '');
    _wabaCtrl = TextEditingController(
        text: widget.channel['waba_id'] as String?
            ?? creds['waba_id'] as String? ?? '');
    _tokenCtrl = TextEditingController(
        text: widget.channel['wa_token'] as String?
            ?? creds['access_token'] as String? ?? '');
    _pinCtrl        = TextEditingController();
    _pinConfirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _wabaCtrl.dispose();
    _tokenCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfirmCtrl.dispose();
    super.dispose();
  }

  bool get _isPinValid {
    final pin = _pinCtrl.text.trim();
    return pin.length == 6 && RegExp(r'^\d{6}$').hasMatch(pin) && pin == _pinConfirmCtrl.text.trim();
  }

  Future<void> _saveCredentials() async {
    final phone = _phoneCtrl.text.trim();
    final waba  = _wabaCtrl.text.trim();
    final token = _tokenCtrl.text.trim();
    if (phone.isEmpty || waba.isEmpty || token.isEmpty) {
      widget.onError('Completa todos los campos de credenciales');
      return;
    }
    if (!_isPinValid) {
      widget.onError('El PIN debe tener exactamente 6 dígitos numéricos y coincidir en ambos campos');
      return;
    }
    // Step 1: verify credentials against Meta
    setState(() { _verifying = true; _verifyError = null; });
    try {
      await ChannelsApi.verifyCredentials(phoneNumberId: phone, accessToken: token);
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _verifyError = _dioError(e); });
      return;
    }
    if (!mounted) return;
    // Step 2: activate WhatsApp channel on Meta
    try {
      await ChannelsApi.activateWhatsapp(
        phoneNumberId: phone,
        wabaId:        waba,
        accessToken:   token,
        pin:           _pinCtrl.text.trim(),
      );
    } catch (e) {
      if (mounted) setState(() { _verifying = false; _verifyError = _dioError(e); });
      return;
    }
    if (!mounted) return;
    setState(() { _verifying = false; _saving = true; });
    // Step 3: persist credentials
    try {
      final updated = await ChannelsApi.updateChannel(
        channelId: widget.channel['id'] as String,
        tenantId: widget.tenantId,
        phoneNumberId: phone,
        wabaId: waba,
        waToken: token,
      );
      widget.onUpdated(updated);
      TemplatesApi.syncTemplates(
        channelId: widget.channel['id'] as String,
        tenantId: widget.tenantId,
      ).catchError((_) {});
      widget.onSuccess('Credenciales guardadas');
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        final data = e.response?.data;
        final errorCode = data is Map ? data['error'] as String? : null;
        if (errorCode == 'channel_has_history') {
          final msg = data is Map
              ? (data['message'] as String? ?? 'Este canal tiene historial.')
              : 'Este canal tiene historial.';
          if (mounted) setState(() => _credentialsLocked = true);
          widget.onError(msg);
          return;
        }
      }
      widget.onError(_dioError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Embedded Signup (disabled) ──
          _SectionCard(
            title: 'Conexión rápida',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.ctTealLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Requiere certificación Tech Provider',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctTealDark,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Tooltip(
                  message:
                      'Disponible cuando Conectamos obtenga certificación Meta Tech Provider',
                  child: Opacity(
                    opacity: 0.5,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1565C0),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                bottomLeft: Radius.circular(8),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'f',
                              style: TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Conectar con WhatsApp Business',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Manual credentials ──
          _SectionCard(
            title: 'Credenciales manuales',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_credentialsLocked) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.ctWarnBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.ctWarnText.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.ctWarnText),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Este canal tiene historial. Para cambiar el número o WABA, desactiva este canal y crea uno nuevo.',
                            style: TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12.5,
                              color: AppColors.ctWarnText,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                _FieldLabel('Phone Number ID'),
                const SizedBox(height: 6),
                _StyledTextField(
                    controller: _phoneCtrl,
                    hint: '123456789012345',
                    enabled: !_credentialsLocked),
                const SizedBox(height: 16),
                _FieldLabel('WABA ID'),
                const SizedBox(height: 6),
                _StyledTextField(
                    controller: _wabaCtrl,
                    hint: '987654321098765',
                    enabled: !_credentialsLocked),
                const SizedBox(height: 16),
                _FieldLabel('Access Token'),
                const SizedBox(height: 6),
                _StyledTextField(
                  controller: _tokenCtrl,
                  hint: 'EAAxxxx...',
                  obscure: !_showToken,
                  enabled: !_credentialsLocked,
                  suffix: IconButton(
                    icon: Icon(
                      _showToken ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                      color: AppColors.ctText2,
                    ),
                    onPressed: () =>
                        setState(() => _showToken = !_showToken),
                  ),
                ),
                if (!_credentialsLocked) ...[
                  const SizedBox(height: 16),
                  _FieldLabel('PIN de verificación (6 dígitos)'),
                  const SizedBox(height: 6),
                  _StyledTextField(
                    controller: _pinCtrl,
                    hint: '6 dígitos numéricos',
                    obscure: !_showPin,
                    suffix: IconButton(
                      icon: Icon(_showPin ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.ctText2),
                      onPressed: () => setState(() => _showPin = !_showPin),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel('Confirmar PIN'),
                  const SizedBox(height: 6),
                  _StyledTextField(
                    controller: _pinConfirmCtrl,
                    hint: 'Repite los 6 dígitos',
                    obscure: !_showPinConfirm,
                    suffix: IconButton(
                      icon: Icon(_showPinConfirm ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.ctText2),
                      onPressed: () => setState(() => _showPinConfirm = !_showPinConfirm),
                    ),
                  ),
                ],
                if (!_credentialsLocked) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _verifying
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(color: AppColors.ctTeal, borderRadius: BorderRadius.circular(8)),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctNavy)),
                                SizedBox(width: 8),
                                Text('Verificando...', style: TextStyle(fontFamily: 'Geist', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ctNavy)),
                              ],
                            ),
                          )
                        : _PrimaryButton(
                            label: 'Guardar credenciales',
                            loading: _saving,
                            onTap: _saveCredentials,
                          ),
                  ),
                  if (_verifyError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: AppColors.ctRedBg, borderRadius: BorderRadius.circular(8)),
                      child: Text(_verifyError!, style: const TextStyle(fontFamily: 'Geist', fontSize: 12, color: AppColors.ctRedText)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TAB 3 — Plantillas ────────────────────────────────────────────────────────

class _TemplatesTab extends StatefulWidget {
  const _TemplatesTab({
    required this.channelId,
    required this.tenantId,
    required this.onError,
    required this.onSuccess,
  });
  final String channelId;
  final String tenantId;
  final ValueChanged<String> onError;
  final ValueChanged<String> onSuccess;

  @override
  State<_TemplatesTab> createState() => _TemplatesTabState();
}

class _TemplatesTabState extends State<_TemplatesTab> {
  List<Map<String, dynamic>> _templates = [];
  bool _loading = true;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _fetchTemplates();
  }

  Future<void> _fetchTemplates() async {
    setState(() => _loading = true);
    try {
      final list = await TemplatesApi.listTemplates(
          channelId: widget.channelId, tenantId: widget.tenantId);
      if (mounted) setState(() { _templates = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _templates = []; _loading = false; });
    }
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      await TemplatesApi.syncTemplates(
          channelId: widget.channelId, tenantId: widget.tenantId);
      widget.onSuccess('Plantillas sincronizadas');
      await _fetchTemplates();
    } catch (e) {
      widget.onError(_dioError(e));
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  ({String label, Color bg, Color fg}) _statusStyle(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'APPROVED':
        return (label: 'Aprobada', bg: AppColors.ctOkBg, fg: AppColors.ctOkText);
      case 'PENDING':
      case 'PENDING_DELETION':
        return (label: 'Pendiente', bg: AppColors.ctWarnBg, fg: AppColors.ctWarnText);
      case 'REJECTED':
      case 'PAUSED':
      case 'DISABLED':
        return (label: 'Rechazada', bg: AppColors.ctRedBg, fg: AppColors.ctRedText);
      default:
        return (label: status ?? '—', bg: AppColors.ctSurface2, fg: AppColors.ctText2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: const BoxDecoration(
            color: AppColors.ctSurface,
            border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
          ),
          child: Row(
            children: [
              Text(
                '${_templates.length} plantillas',
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText2,
                ),
              ),
              const Spacer(),
              _syncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : _OutlineButton(
                      label: 'Sincronizar con Meta',
                      danger: false,
                      onTap: _sync,
                    ),
            ],
          ),
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _templates.isEmpty
                  ? const Center(
                      child: Text(
                        'Sin plantillas. Sincroniza para obtenerlas.',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.ctText2,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(24),
                      itemCount: _templates.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final t = _templates[i];
                        final style = _statusStyle(t['status'] as String?);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.ctSurface,
                            border: Border.all(color: AppColors.ctBorder),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['name'] as String? ?? '—',
                                      style: const TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.ctText,
                                      ),
                                    ),
                                    if ((t['body_text'] as String?) != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          t['body_text'] as String,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontFamily: 'Geist',
                                            fontSize: 12,
                                            color: AppColors.ctText2,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: style.bg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      style.label,
                                      style: TextStyle(
                                        fontFamily: 'Geist',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: style.fg,
                                      ),
                                    ),
                                  ),
                                  if ((t['language'] as String?) != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        t['language'] as String,
                                        style: const TextStyle(
                                          fontFamily: 'Geist',
                                          fontSize: 11,
                                          color: AppColors.ctText3,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// ── TAB 4 — Bienvenida ────────────────────────────────────────────────────────

class _WelcomeTab extends StatefulWidget {
  const _WelcomeTab({
    required this.channel,
    required this.tenantId,
    required this.onError,
    required this.onSuccess,
  });
  final Map<String, dynamic> channel;
  final String tenantId;
  final ValueChanged<String> onError;
  final ValueChanged<String> onSuccess;

  @override
  State<_WelcomeTab> createState() => _WelcomeTabState();
}

class _WelcomeTabState extends State<_WelcomeTab> {
  List<Map<String, dynamic>> _approved = [];
  String? _selectedId;
  bool _loading = true;
  bool _saving  = false;

  @override
  void initState() {
    super.initState();
    _loadApproved();
  }

  Future<void> _loadApproved() async {
    try {
      final all = await TemplatesApi.listTemplates(
          channelId: widget.channel['id'] as String,
          tenantId: widget.tenantId);
      final approved = all
          .where((t) =>
              (t['status'] as String? ?? '').toUpperCase() == 'APPROVED')
          .toList();
      if (!mounted) return;
      final currentId =
          widget.channel['welcome_template_id'] as String?;
      setState(() {
        _approved = approved;
        _selectedId = currentId;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_selectedId == null) return;
    setState(() => _saving = true);
    try {
      await ChannelsApi.updateWelcomeTemplate(
        channelId: widget.channel['id'] as String,
        templateId: _selectedId!,
      );
      widget.onSuccess('Plantilla de bienvenida actualizada');
    } catch (e) {
      widget.onError(_dioError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic>? get _preview =>
      _approved.where((t) => t['id'] == _selectedId).firstOrNull;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: _SectionCard(
        title: 'Plantilla de bienvenida',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se envía automáticamente cuando un usuario escribe por primera vez.',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.ctText2,
              ),
            ),
            const SizedBox(height: 16),
            if (_selectedId == null && _approved.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF92400E)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No hay plantilla de bienvenida configurada.',
                        style: TextStyle(fontFamily: 'Geist', fontSize: 12, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            _FieldLabel('Seleccionar plantilla aprobada'),
            const SizedBox(height: 8),
            if (_approved.isEmpty)
              const Text(
                'No hay plantillas aprobadas. Sincroniza en la pestaña Plantillas.',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText2,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ctBorder),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.ctSurface,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedId,
                    isExpanded: true,
                    hint: const Text(
                      'Selecciona una plantilla',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctText2,
                      ),
                    ),
                    items: [
                      for (final t in _approved)
                        DropdownMenuItem(
                          value: t['id'] as String?,
                          child: Text(
                            t['name'] as String? ?? t['id'].toString(),
                            style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 13,
                              color: AppColors.ctText,
                            ),
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() => _selectedId = v),
                  ),
                ),
              ),

            // Preview
            if (_preview != null) ...[
              const SizedBox(height: 16),
              _FieldLabel('Vista previa'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFF6EE7B7)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _preview!['body_text'] as String? ?? '(sin texto de cuerpo)',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: _PrimaryButton(
                label: 'Guardar',
                loading: _saving,
                onTap: _selectedId != null ? _save : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.ctBorder, height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText2,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.enabled = true,
  });
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          color: enabled ? AppColors.ctText : AppColors.ctText3),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText3),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        filled: true,
        fillColor: enabled ? AppColors.ctSurface : AppColors.ctSurface2,
        suffixIcon: suffix,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctTeal, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.ctBorder),
        ),
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.selected, required this.onChanged});
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final hex in _kColorPalette) ...[
          GestureDetector(
            onTap: () => onChanged(hex),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _hexColor(hex),
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == hex
                      ? AppColors.ctText
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: selected == hex
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _WorkerDropdown extends StatelessWidget {
  const _WorkerDropdown({
    required this.workers,
    required this.value,
    required this.onChanged,
  });
  final List<Map<String, dynamic>> workers;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.ctSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: workers.any((w) => w['id'].toString() == value) ? value : null,
          isExpanded: true,
          hint: const Text(
            'Sin worker asignado',
            style: TextStyle(
                fontFamily: 'Geist', fontSize: 13, color: AppColors.ctText2),
          ),
          items: [
            for (final w in workers)
              DropdownMenuItem(
                value: w['id'].toString(),
                child: Text(
                  w['display_name'] as String? ?? w['id'].toString(),
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 13,
                      color: AppColors.ctText),
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _OperatorRow extends StatelessWidget {
  const _OperatorRow({required this.op});
  final Map<String, dynamic> op;

  @override
  Widget build(BuildContext context) {
    final name = op['nombre'] as String?
        ?? op['display_name'] as String?
        ?? op['phone'] as String?
        ?? '?';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.ctTealLight,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.ctTealDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _TypeChip extends StatelessWidget {
  const _TypeChip(this.type);
  final String type;

  @override
  Widget build(BuildContext context) {
    final cfg = _kChannelTypeConfig[type] ??
        (label: type, bg: AppColors.ctSurface2, fg: AppColors.ctText2);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        cfg.label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: cfg.fg,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.isActive);
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isActive ? AppColors.ctOkBg : AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isActive ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isActive ? AppColors.ctOkText : AppColors.ctText2,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null && !widget.loading;
    return MouseRegion(
      cursor: enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: enabled
                ? (_hovered ? AppColors.ctTealDark : AppColors.ctTeal)
                : AppColors.ctBorder,
            borderRadius: BorderRadius.circular(8),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        enabled ? AppColors.ctNavy : AppColors.ctText2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _OutlineButton extends StatefulWidget {
  const _OutlineButton({
    required this.label,
    required this.danger,
    required this.onTap,
  });
  final String label;
  final bool danger;
  final VoidCallback? onTap;

  @override
  State<_OutlineButton> createState() => _OutlineButtonState();
}

class _OutlineButtonState extends State<_OutlineButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.danger ? AppColors.ctDanger : AppColors.ctBorder2;
    final textColor = widget.danger ? AppColors.ctDanger : AppColors.ctText2;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.danger ? AppColors.ctRedBg : AppColors.ctSurface2)
                : AppColors.ctSurface,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}
