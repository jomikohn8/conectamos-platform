import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/ai_workers_api.dart';
import '../../core/api/channels_api.dart';
import '../../core/api/operators_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const _kColorPalette = [
  '#2DD4BF', '#818CF8', '#FB923C', '#F472B6', '#34D399', '#60A5FA',
];

const _kChannelTypeConfig = {
  'whatsapp': (label: 'WhatsApp', bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF)),
  'telegram': (label: 'Telegram', bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9)),
  'sms':      (label: 'SMS',      bg: Color(0xFFFFEDD5), fg: Color(0xFFC2410C)),
};

const _kChannelTypeOptions = ['whatsapp', 'telegram', 'sms'];

// ── Helpers ───────────────────────────────────────────────────────────────────

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  return name.isEmpty ? '?' : name[0].toUpperCase();
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

List<Map<String, dynamic>> _parseOps(dynamic raw) =>
    (raw as List<dynamic>? ?? [])
        .whereType<Map>()
        .map((o) => Map<String, dynamic>.from(o))
        .toList();

// ── Screen ────────────────────────────────────────────────────────────────────

class ChannelsScreen extends ConsumerStatefulWidget {
  const ChannelsScreen({super.key});

  @override
  ConsumerState<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends ConsumerState<ChannelsScreen> {
  List<Map<String, dynamic>> _channels  = [];
  List<Map<String, dynamic>> _workers   = [];
  List<Map<String, dynamic>> _operators = [];
  bool    _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final results = await Future.wait([
        ChannelsApi.listChannels(tenantId: tenantId),
        AiWorkersApi.listWorkers(tenantId: tenantId),
        OperatorsApi.listOperators(tenantId: tenantId),
      ]);
      if (!mounted) return;
      setState(() {
        _channels  = results[0];
        _workers   = results[1];
        _operators = results[2];
        _loading   = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = _dioError(e); });
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> channel) async {
    final id       = channel['id'] as String? ?? '';
    final isActive = channel['is_active'] as bool? ?? false;
    try {
      await ChannelsApi.updateChannel(channelId: id, isActive: !isActive);
      await _fetchAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  void _openCreate() async {
    await showDialog(
      context: context,
      builder: (_) => _ChannelFormDialog(
        workers: _workers,
        tenantId: ref.read(activeTenantIdProvider),
        onRefresh: _fetchAll,
      ),
    );
  }

  void _openEdit(Map<String, dynamic> channel) async {
    await showDialog(
      context: context,
      builder: (_) => _ChannelFormDialog(
        channel: channel,
        workers: _workers,
        tenantId: ref.read(activeTenantIdProvider),
        onRefresh: _fetchAll,
      ),
    );
  }

  void _openAssign(Map<String, dynamic> channel) async {
    await showDialog(
      context: context,
      builder: (_) => _AssignOperatorsDialog(
        channel: channel,
        operators: _operators,
        tenantId: ref.read(activeTenantIdProvider),
        onClose: _fetchAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBar(loading: _loading, onAdd: _openCreate),
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.ctTeal, strokeWidth: 2,
                  ),
                )
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.ctDanger,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          _GhostBtn(label: 'Reintentar', onTap: _fetchAll),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(22),
                      child: _ChannelsBody(
                        channels: _channels,
                        onEdit: _openEdit,
                        onAssign: _openAssign,
                        onToggleActive: _toggleActive,
                      ),
                    ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.loading, required this.onAdd});
  final bool loading;
  final VoidCallback onAdd;

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
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Canales',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Conecta números de WhatsApp con AI Workers y operadores',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryBtn(label: '+ Nuevo canal', onTap: onAdd, disabled: loading),
        ],
      ),
    );
  }
}

// ── Channels body ─────────────────────────────────────────────────────────────

class _ChannelsBody extends StatelessWidget {
  const _ChannelsBody({
    required this.channels,
    required this.onEdit,
    required this.onAssign,
    required this.onToggleActive,
  });
  final List<Map<String, dynamic>> channels;
  final void Function(Map<String, dynamic>) onEdit;
  final void Function(Map<String, dynamic>) onAssign;
  final void Function(Map<String, dynamic>) onToggleActive;

  static const _headerStyle = TextStyle(
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
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(9),
                topRight: Radius.circular(9),
              ),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('CANAL',      style: _headerStyle)),
                Expanded(flex: 2, child: Text('AI WORKER',  style: _headerStyle)),
                Expanded(flex: 2, child: Text('OPERADORES', style: _headerStyle)),
                Expanded(flex: 1, child: Text('ESTADO',     style: _headerStyle)),
                Expanded(flex: 2, child: Text('ACCIONES',   style: _headerStyle)),
              ],
            ),
          ),

          // Rows
          if (channels.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No hay canales configurados aún.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.ctText2,
                  ),
                ),
              ),
            )
          else
            ...channels.asMap().entries.map((entry) {
              final isLast = entry.key == channels.length - 1;
              return Column(
                children: [
                  _ChannelRow(
                    channel: entry.value,
                    onEdit: () => onEdit(entry.value),
                    onAssign: () => onAssign(entry.value),
                    onToggleActive: () => onToggleActive(entry.value),
                  ),
                  if (!isLast)
                    const Divider(height: 1, color: AppColors.ctBorder),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ── Channel row ───────────────────────────────────────────────────────────────

class _ChannelRow extends StatefulWidget {
  const _ChannelRow({
    required this.channel,
    required this.onEdit,
    required this.onAssign,
    required this.onToggleActive,
  });
  final Map<String, dynamic> channel;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onToggleActive;

  @override
  State<_ChannelRow> createState() => _ChannelRowState();
}

class _ChannelRowState extends State<_ChannelRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ch          = widget.channel;
    final name        = ch['display_name'] as String? ?? ch['name'] as String? ?? '—';
    final colorHex    = ch['color'] as String? ?? '#2DD4BF';
    final channelType = ch['channel_type'] as String? ?? 'whatsapp';
    final isActive    = ch['is_active'] as bool? ?? false;

    final workerName  = ch['ai_worker_name']  as String? ?? '';
    final workerColor = ch['ai_worker_color'] as String? ?? '#9CA3AF';

    final ops = _parseOps(ch['operators']);

    final typeEntry = _kChannelTypeConfig[channelType] ??
        _kChannelTypeConfig['whatsapp']!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── CANAL ─────────────────────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _hexColor(colorHex),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeEntry.bg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            typeEntry.label,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: typeEntry.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── AI WORKER ─────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: workerName.isEmpty
                  ? const Text(
                      'Sin worker',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: AppColors.ctText3,
                      ),
                    )
                  : Row(
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
                        Flexible(
                          child: Text(
                            workerName,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.ctText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
            ),

            // ── OPERADORES ────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: _OperatorAvatars(operators: ops),
            ),

            // ── ESTADO ────────────────────────────────────────────────────────
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.ctOkBg
                        : AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? AppColors.ctOkText
                          : AppColors.ctText2,
                    ),
                  ),
                ),
              ),
            ),

            // ── ACCIONES ──────────────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionBtn(
                    label: 'Editar',
                    color: AppColors.ctInfo,
                    onTap: widget.onEdit,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    label: 'Operadores',
                    color: AppColors.ctTeal,
                    onTap: widget.onAssign,
                  ),
                  const SizedBox(width: 4),
                  _ActionBtn(
                    label: isActive ? 'Desactivar' : 'Activar',
                    color: isActive ? AppColors.ctDanger : AppColors.ctOk,
                    onTap: widget.onToggleActive,
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

// ── Operator avatars ──────────────────────────────────────────────────────────

class _OperatorAvatars extends StatelessWidget {
  const _OperatorAvatars({required this.operators});
  final List<Map<String, dynamic>> operators;

  @override
  Widget build(BuildContext context) {
    if (operators.isEmpty) {
      return const Text(
        'Sin operadores',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          color: AppColors.ctText3,
        ),
      );
    }
    final visible = operators.take(3).toList();
    final extra   = operators.length - visible.length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...visible.map((op) {
          final name = op['display_name'] as String? ??
              op['name'] as String? ?? '?';
          return Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 4),
            decoration: const BoxDecoration(
              color: AppColors.ctTeal,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(name),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.ctNavy,
              ),
            ),
          );
        }),
        if (extra > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.ctBorder),
            ),
            child: Text(
              '+$extra',
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
  }
}

// ── Channel form dialog ───────────────────────────────────────────────────────

class _ChannelFormDialog extends StatefulWidget {
  const _ChannelFormDialog({
    this.channel,
    required this.workers,
    required this.tenantId,
    required this.onRefresh,
  });
  final Map<String, dynamic>? channel;
  final List<Map<String, dynamic>> workers;
  final String tenantId;
  final Future<void> Function() onRefresh;

  bool get isEdit => channel != null;

  @override
  State<_ChannelFormDialog> createState() => _ChannelFormDialogState();
}

class _ChannelFormDialogState extends State<_ChannelFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _wabaCtrl;
  late final TextEditingController _tokenCtrl;
  late String  _channelType;
  late String  _color;
  String?      _workerId;
  bool         _tokenVisible = false;
  bool         _saving       = false;
  String?      _errorMsg;

  @override
  void initState() {
    super.initState();
    final ch = widget.channel;
    _nameCtrl  = TextEditingController(text: ch?['display_name'] as String? ?? ch?['name'] as String? ?? '');
    _phoneCtrl = TextEditingController(text: ch?['phone_number_id'] as String? ?? '');
    _wabaCtrl  = TextEditingController(text: ch?['waba_id'] as String? ?? '');
    _tokenCtrl = TextEditingController(text: ch?['wa_token'] as String? ?? '');
    _channelType = ch?['channel_type'] as String? ?? 'whatsapp';
    _color       = ch?['color'] as String? ?? _kColorPalette.first;

    // Set worker id — try to match with loaded workers list
    final rawWorkerId = ch?['ai_worker_id'] as String?;
    if (rawWorkerId != null &&
        widget.workers.any((w) => (w['id'] as String?) == rawWorkerId)) {
      _workerId = rawWorkerId;
    } else if (widget.workers.isNotEmpty) {
      _workerId = widget.workers.first['id'] as String?;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _wabaCtrl.dispose();
    _tokenCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _errorMsg = 'El nombre del canal es obligatorio.');
      return;
    }
    if (_workerId == null || _workerId!.isEmpty) {
      setState(() => _errorMsg = 'Selecciona un AI Worker.');
      return;
    }

    setState(() { _saving = true; _errorMsg = null; });

    try {
      if (widget.isEdit) {
        await ChannelsApi.updateChannel(
          channelId:    widget.channel!['id'] as String,
          displayName:  name,
          color:        _color,
          aiWorkerId:   _workerId,
          channelType: _channelType,
          phoneNumberId: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          wabaId:        _wabaCtrl.text.trim().isEmpty  ? null : _wabaCtrl.text.trim(),
          waToken:       _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
        );
      } else {
        await ChannelsApi.createChannel(
          tenantId:      widget.tenantId,
          aiWorkerId:    _workerId!,
          displayName:   name,
          color:         _color,
          channelType:   _channelType,
          phoneNumberId: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          wabaId:        _wabaCtrl.text.trim().isEmpty  ? null : _wabaCtrl.text.trim(),
          waToken:       _tokenCtrl.text.trim().isEmpty ? null : _tokenCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      await widget.onRefresh();
    } catch (e) {
      if (!mounted) return;
      setState(() { _saving = false; _errorMsg = _dioError(e); });
    }
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
    hintText: hint,
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
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.ctText,
      ),
    ),
  );

  Widget _dropdownBox(Widget child) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.ctSurface2,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.ctBorder2),
    ),
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.isEdit ? 'Editar canal' : 'Nuevo canal',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // 1. Nombre
              _label('Nombre del canal'),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                decoration: _fieldDecoration('Ej: Canal Logística Norte'),
              ),
              const SizedBox(height: 14),

              // 2. AI Worker
              _label('AI Worker'),
              widget.workers.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.ctSurface2,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.ctBorder2),
                      ),
                      child: const Text(
                        'No hay AI Workers disponibles',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText3),
                      ),
                    )
                  : _dropdownBox(
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _workerId,
                          isExpanded: true,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.ctText3),
                          items: widget.workers.map((w) {
                            final wId    = w['id']    as String? ?? '';
                            final wName  = w['name']  as String? ?? w['display_name'] as String? ?? '—';
                            final wColor = w['color'] as String? ?? '#9CA3AF';
                            return DropdownMenuItem<String>(
                              value: wId,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10, height: 10,
                                    decoration: BoxDecoration(
                                      color: _hexColor(wColor), shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(wName),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (v) { if (v != null) setState(() => _workerId = v); },
                        ),
                      ),
                    ),
              const SizedBox(height: 14),

              // 3. Color
              _label('Color del canal'),
              Row(
                children: _kColorPalette.map((hex) {
                  final selected = _color == hex;
                  final c = _hexColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 28, height: 28,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(color: AppColors.ctNavy, width: 2)
                              : null,
                          boxShadow: selected
                              ? [BoxShadow(color: c.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // 4. Tipo de canal
              _label('Tipo de canal'),
              _dropdownBox(
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _channelType,
                    isExpanded: true,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.ctText3),
                    items: _kChannelTypeOptions.map((t) {
                      final cfg = _kChannelTypeConfig[t] ?? _kChannelTypeConfig['whatsapp']!;
                      return DropdownMenuItem<String>(value: t, child: Text(cfg.label));
                    }).toList(),
                    onChanged: (v) { if (v != null) setState(() => _channelType = v); },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 5. Phone Number ID
              _label('Phone Number ID (opcional)'),
              TextField(
                controller: _phoneCtrl,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                decoration: _fieldDecoration('ej. 1077435892114696'),
              ),
              const SizedBox(height: 14),

              // 6. WABA ID
              _label('WABA ID (opcional)'),
              TextField(
                controller: _wabaCtrl,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                decoration: _fieldDecoration('ej. 1744815743186774'),
              ),
              const SizedBox(height: 14),

              // 7. Token de WhatsApp
              _label('Token de WhatsApp (opcional)'),
              TextField(
                controller: _tokenCtrl,
                obscureText: !_tokenVisible,
                style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
                decoration: _fieldDecoration('Token de acceso de Meta').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _tokenVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.ctText3,
                    ),
                    onPressed: () => setState(() => _tokenVisible = !_tokenVisible),
                  ),
                ),
              ),

              // Error
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ctRedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ctRedText),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostBtn(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _saving
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.ctTeal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.ctNavy,
                            ),
                          ),
                        )
                      : _PrimaryBtn(label: 'Guardar canal', onTap: _save),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assign operators dialog ───────────────────────────────────────────────────

class _AssignOperatorsDialog extends StatefulWidget {
  const _AssignOperatorsDialog({
    required this.channel,
    required this.operators,
    required this.tenantId,
    required this.onClose,
  });
  final Map<String, dynamic> channel;
  final List<Map<String, dynamic>> operators;
  final String tenantId;
  final Future<void> Function() onClose;

  @override
  State<_AssignOperatorsDialog> createState() => _AssignOperatorsDialogState();
}

class _AssignOperatorsDialogState extends State<_AssignOperatorsDialog> {
  late Set<String> _assigned;
  final Set<String> _processing = {};

  String _opId(Map<String, dynamic> op) =>
      op['id'] as String? ?? op['operator_id'] as String? ?? '';

  @override
  void initState() {
    super.initState();
    final channelOps = _parseOps(widget.channel['operators']);
    _assigned = {
      for (final op in channelOps)
        _opId(op),
    }..remove('');
  }

  Future<void> _toggle(Map<String, dynamic> op, bool checked) async {
    final id        = _opId(op);
    final channelId = widget.channel['id'] as String? ?? '';
    if (id.isEmpty || channelId.isEmpty) return;
    if (_processing.contains(id)) return;

    setState(() => _processing.add(id));

    try {
      if (checked) {
        await ChannelsApi.assignOperator(
          channelId:  channelId,
          operatorId: id,
          tenantId:   widget.tenantId,
        );
        if (mounted) setState(() => _assigned.add(id));
      } else {
        await ChannelsApi.removeOperator(channelId: channelId, operatorId: id);
        if (mounted) setState(() => _assigned.remove(id));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
      // revert
      setState(() {
        if (checked) { _assigned.remove(id); } else { _assigned.add(id); }
      });
    } finally {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelName = widget.channel['display_name'] as String? ??
        widget.channel['name'] as String? ?? 'Canal';

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operadores en $channelName',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Los operadores asignados pueden ver las conversaciones de este canal.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.ctBorder),

            // Lista de operadores
            Flexible(
              child: widget.operators.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No hay operadores disponibles.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText2,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      itemCount: widget.operators.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.ctBorder),
                      itemBuilder: (_, i) {
                        final op     = widget.operators[i];
                        final id     = _opId(op);
                        final name   = op['display_name'] as String? ?? op['name'] as String? ?? '—';
                        final phone  = op['phone'] as String? ?? '';
                        final isChecked   = _assigned.contains(id);
                        final isProcessing = _processing.contains(id);

                        return CheckboxListTile(
                          value: isChecked,
                          onChanged: isProcessing
                              ? null
                              : (v) => _toggle(op, v ?? false),
                          activeColor: AppColors.ctTeal,
                          checkColor: AppColors.ctNavy,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          secondary: isProcessing
                              ? const SizedBox(
                                  width: 32, height: 32,
                                  child: Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.ctTeal,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 32, height: 32,
                                  decoration: const BoxDecoration(
                                    color: AppColors.ctTeal,
                                    shape: BoxShape.circle,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ctNavy,
                                    ),
                                  ),
                                ),
                          title: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ctText,
                            ),
                          ),
                          subtitle: phone.isNotEmpty
                              ? Text(
                                  phone,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.ctText2,
                                  ),
                                )
                              : null,
                        );
                      },
                    ),
            ),

            const Divider(height: 1, color: AppColors.ctBorder),

            // Botón cerrar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostBtn(
                    label: 'Cerrar',
                    onTap: () async {
                      Navigator.pop(context);
                      await widget.onClose();
                    },
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

// ── Button helpers ────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  const _PrimaryBtn({
    required this.label,
    required this.onTap,
    this.disabled = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool disabled;

  @override
  State<_PrimaryBtn> createState() => _PrimaryBtnState();
}

class _PrimaryBtnState extends State<_PrimaryBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.disabled ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: widget.disabled
                ? AppColors.ctBorder2
                : _hovered
                    ? AppColors.ctTealDark
                    : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.disabled ? AppColors.ctText3 : AppColors.ctNavy,
            ),
          ),
        ),
      ),
    );
  }
}

class _GhostBtn extends StatefulWidget {
  const _GhostBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_GhostBtn> createState() => _GhostBtnState();
}

class _GhostBtnState extends State<_GhostBtn> {
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
            border: Border.all(color: AppColors.ctBorder),
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

class _ActionBtn extends StatefulWidget {
  const _ActionBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
