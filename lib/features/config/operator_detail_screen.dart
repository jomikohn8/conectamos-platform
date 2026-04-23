import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/api/operators_api.dart';
import '../../core/providers/permissions_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/identity_config.dart';
import 'widgets/operator_form_dialog.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

String _fmtDate(String? iso) {
  if (iso == null) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/${dt.year} $h:$min';
  } catch (_) {
    return iso;
  }
}

({String label, Color bg, Color fg}) _statusStyle(String? status) {
  switch (status) {
    case 'active':
      return (label: 'Activo', bg: AppColors.ctOkBg, fg: AppColors.ctOkText);
    case 'incident':
      return (label: 'Incidencia', bg: AppColors.ctRedBg, fg: AppColors.ctRedText);
    case 'suspended':
      return (label: 'Suspendido', bg: AppColors.ctSurface2, fg: AppColors.ctText2);
    default:
      return (label: 'Sin inicio', bg: AppColors.ctSurface2, fg: AppColors.ctText2);
  }
}

enum _MenuAction { edit, suspend, reactivate, delete }

// ── Screen ────────────────────────────────────────────────────────────────────

class OperatorDetailScreen extends ConsumerStatefulWidget {
  const OperatorDetailScreen({super.key, required this.operatorId});
  final String operatorId;

  @override
  ConsumerState<OperatorDetailScreen> createState() =>
      _OperatorDetailScreenState();
}

class _OperatorDetailScreenState extends ConsumerState<OperatorDetailScreen>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic>? _op;
  bool _loading = true;
  String? _error;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final op = await OperatorsApi.getOperator(widget.operatorId);
      if (mounted) setState(() { _op = op; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _patchStatus(String status) async {
    final name = _op?['display_name'] as String? ?? 'este operador';
    final isSuspend = status == 'suspended';
    final label = isSuspend ? 'Suspender' : 'Reactivar';
    final consequence = isSuspend
        ? 'No podrá recibir nuevas conversaciones hasta ser reactivado.'
        : 'Volverá a recibir conversaciones nuevas.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: '¿$label a $name?',
        body: consequence,
        confirmLabel: label,
        confirmColor: isSuspend ? AppColors.ctDanger : AppColors.ctOk,
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await OperatorsApi.patchStatus(id: widget.operatorId, status: status);
      if (mounted) setState(() => _op = {..._op!, 'status': status});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al cambiar el estado'),
          backgroundColor: AppColors.ctDanger,
        ));
      }
    }
  }

  Future<void> _delete() async {
    final name = _op?['display_name'] as String? ?? 'este operador';

    final step1 = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDialog(
        title: '¿Eliminar a $name?',
        body: 'Esta acción no se puede deshacer.',
        confirmLabel: 'Eliminar permanentemente',
        confirmColor: AppColors.ctDanger,
      ),
    );
    if (step1 != true || !mounted) return;

    try {
      final res =
          await ApiClient.instance.delete('/operators/${widget.operatorId}');
      final data = res.data is Map
          ? Map<String, dynamic>.from(res.data as Map)
          : <String, dynamic>{};
      final telegramLinked = data['telegram_linked'] as bool? ?? false;

      if (!mounted) return;

      if (telegramLinked) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.ctSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text('Telegram vinculado',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            content: const Text(
              'Este operador tenía Telegram vinculado. Ha perdido acceso al bot.',
              style: TextStyle(
                  fontFamily: 'Geist', fontSize: 14, color: AppColors.ctText2),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido',
                    style: TextStyle(
                        fontFamily: 'Geist', color: AppColors.ctText2)),
              ),
            ],
          ),
        );
      }

      if (!mounted) return;
      context.go('/operators');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Operador eliminado'),
        backgroundColor: AppColors.ctOk,
      ));
    } catch (e) {
      if (!mounted) return;
      String msg = 'Error al eliminar el operador';
      if (e is DioException) {
        final body = e.response?.data;
        if (body is Map) {
          final code = body['code'] as String?;
          final detail = body['message'] ?? body['detail'];
          if (code == 'OP_E017' && detail != null) {
            msg = detail.toString();
          } else if (detail != null) {
            msg = detail.toString();
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.ctDanger));
    }
  }

  Future<void> _openEdit() async {
    final op = _op!;
    final meta = op['metadata'] as Map<String, dynamic>? ?? {};
    final flows = (op['flows'] as List? ?? []).map((f) {
      if (f is Map) return Map<String, dynamic>.from(f);
      return <String, dynamic>{'id': f.toString()};
    }).toList();

    await showDialog(
      context: context,
      builder: (_) => OperatorFormDialog(
        operatorId: widget.operatorId,
        initialName:
            op['display_name'] as String? ?? op['name'] as String? ?? '',
        initialPhone: op['phone'] as String? ?? '',
        initialFlows: flows
            .map((f) => f['id'] as String? ?? '')
            .where((s) => s.isNotEmpty)
            .toList(),
        initialTelegramChatId: meta['telegram_chat_id'] as String?,
        initialMetadata: meta,
        initialEmail: op['email'] as String?,
        initialNationality: op['nationality'] as String?,
        initialIdentityNumber: op['identity_number'] as String?,
        initialProfilePictureUrl: op['profile_picture_url'] as String?,
        onSaved: _load,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(null),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _op == null) {
      return Scaffold(
        backgroundColor: AppColors.ctBg,
        appBar: _buildAppBar(null),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: AppColors.ctDanger),
              const SizedBox(height: 12),
              Text(_error ?? 'No se encontró el operador',
                  style: const TextStyle(
                      fontFamily: 'Geist', color: AppColors.ctText2)),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: _load, child: const Text('Reintentar')),
            ],
          ),
        ),
      );
    }

    final op = _op!;
    final canManage = hasPermission(ref, 'operators', 'manage');
    final status = op['status'] as String?;

    return Scaffold(
      backgroundColor: AppColors.ctBg,
      appBar: _buildAppBar(
        canManage
            ? PopupMenuButton<_MenuAction>(
                icon: const Icon(Icons.more_vert, color: AppColors.ctText),
                color: AppColors.ctSurface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                onSelected: (action) async {
                  switch (action) {
                    case _MenuAction.edit:
                      await _openEdit();
                    case _MenuAction.suspend:
                      await _patchStatus('suspended');
                    case _MenuAction.reactivate:
                      await _patchStatus('active');
                    case _MenuAction.delete:
                      await _delete();
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: _MenuAction.edit,
                    child: _MenuItem(
                        icon: Icons.edit_outlined, label: 'Editar'),
                  ),
                  if (status == 'active' || status == 'incident')
                    const PopupMenuItem(
                      value: _MenuAction.suspend,
                      child: _MenuItem(
                        icon: Icons.pause_circle_outline,
                        label: 'Suspender',
                        danger: true,
                      ),
                    )
                  else
                    const PopupMenuItem(
                      value: _MenuAction.reactivate,
                      child: _MenuItem(
                        icon: Icons.play_circle_outline,
                        label: 'Reactivar',
                        success: true,
                      ),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: _MenuAction.delete,
                    child: _MenuItem(
                      icon: Icons.delete_outline,
                      label: 'Eliminar',
                      danger: true,
                    ),
                  ),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          _OperatorHeader(op: op),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _DatosTab(op: op),
                _FlujosTab(op: op, canManage: canManage),
                const _PermisosTab(),
                _HistorialTab(operatorId: widget.operatorId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(Widget? trailing) {
    final name = _op?['display_name'] as String? ??
        _op?['name'] as String? ??
        'Operador';
    return AppBar(
      backgroundColor: AppColors.ctSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.ctText),
        onPressed: () => context.go('/operators'),
      ),
      title: Text(name,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText,
          )),
      actions: [
        ?trailing,
      ],
      bottom: TabBar(
        controller: _tabCtrl,
        labelColor: AppColors.ctTeal,
        unselectedLabelColor: AppColors.ctText2,
        indicatorColor: AppColors.ctTeal,
        labelStyle: const TextStyle(
            fontFamily: 'Geist', fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontFamily: 'Geist', fontSize: 12),
        tabs: const [
          Tab(text: 'DATOS'),
          Tab(text: 'FLUJOS'),
          Tab(text: 'PERMISOS'),
          Tab(text: 'HISTORIAL'),
        ],
      ),
    );
  }
}

// ── Header ─────────────────────────────────────────────────────────────────────

class _OperatorHeader extends StatelessWidget {
  const _OperatorHeader({required this.op});
  final Map<String, dynamic> op;

  @override
  Widget build(BuildContext context) {
    final name =
        op['display_name'] as String? ?? op['name'] as String? ?? '—';
    final phone = op['phone'] as String? ?? '—';
    final email = op['email'] as String?;
    final status = op['status'] as String?;
    final pic = op['profile_picture_url'] as String?;
    final st = _statusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(bottom: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Row(
        children: [
          // Avatar
          (pic != null && pic.isNotEmpty)
              ? CircleAvatar(
                  radius: 36,
                  backgroundImage: NetworkImage(pic),
                  backgroundColor: AppColors.ctSurface2,
                )
              : Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.ctTealLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctTealDark,
                    ),
                  ),
                ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(name,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ctText,
                          ),
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: st.bg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(st.label,
                          style: TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: st.fg,
                          )),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.phone, size: 14, color: AppColors.ctText2),
                  const SizedBox(width: 4),
                  Text(phone,
                      style: const TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          color: AppColors.ctText2)),
                ]),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    const Icon(Icons.email_outlined,
                        size: 14, color: AppColors.ctText2),
                    const SizedBox(width: 4),
                    Text(email,
                        style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 13,
                            color: AppColors.ctText2)),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab DATOS ──────────────────────────────────────────────────────────────────

class _DatosTab extends StatelessWidget {
  const _DatosTab({required this.op});
  final Map<String, dynamic> op;

  @override
  Widget build(BuildContext context) {
    final meta = op['metadata'] as Map<String, dynamic>? ?? {};
    final nationality = op['nationality'] as String? ?? '';
    final identityNumber = op['identity_number'] as String? ?? '';
    final identityType = op['identity_type'] as String?;
    final email = op['email'] as String? ?? '';
    final phone = op['phone'] as String? ?? '';
    final name =
        op['display_name'] as String? ?? op['name'] as String? ?? '—';
    final createdAt = op['created_at'] as String?;
    final updatedAt = op['updated_at'] as String?;
    final createdBy =
        op['created_by'] as String? ?? meta['created_by'] as String? ?? '—';
    final updatedBy =
        op['updated_by'] as String? ?? meta['updated_by'] as String? ?? '—';
    final tgChatId = meta['telegram_chat_id'] as String?;
    final phoneSecondary =
        ((meta['phone_secondary'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    final idConfig =
        nationality.isNotEmpty ? getIdentityConfig(nationality) : null;
    final idLabel = idConfig?.label ?? identityType ?? 'Identidad';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Información personal'),
          const SizedBox(height: 12),
          _FieldRow(label: 'Nombre completo', value: name),
          if (email.isNotEmpty) _FieldRow(label: 'Email', value: email),
          if (nationality.isNotEmpty)
            _FieldRow(label: 'Nacionalidad', value: nationality),
          if (identityNumber.isNotEmpty)
            _FieldRow(label: idLabel, value: identityNumber),
          _FieldRow(label: 'Teléfono WhatsApp', value: phone),
          if (tgChatId != null && tgChatId.isNotEmpty) ...[
            const _FieldLabel('Telegram Chat ID'),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.telegram,
                      size: 14, color: Color(0xFF0088CC)),
                  const SizedBox(width: 5),
                  Text(tgChatId,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF0088CC),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (phoneSecondary.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionTitle('Teléfonos secundarios'),
            const SizedBox(height: 12),
            ...phoneSecondary.map((p) {
              final lbl = p['label'] as String? ?? '—';
              final ch = p['channel'] as String? ?? '';
              final pPhone = p['phone'] as String? ?? '—';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FieldRow(
                  label: lbl + (ch.isNotEmpty ? ' ($ch)' : ''),
                  value: pPhone,
                ),
              );
            }),
          ],
          const SizedBox(height: 16),
          const _SectionTitle('Auditoría'),
          const SizedBox(height: 12),
          _FieldRow(label: 'Creado el', value: _fmtDate(createdAt)),
          _FieldRow(label: 'Creado por', value: createdBy),
          _FieldRow(
              label: 'Última modificación', value: _fmtDate(updatedAt)),
          _FieldRow(label: 'Modificado por', value: updatedBy),
        ],
      ),
    );
  }
}

// ── Tab FLUJOS ─────────────────────────────────────────────────────────────────

class _FlujosTab extends StatelessWidget {
  const _FlujosTab({required this.op, required this.canManage});
  final Map<String, dynamic> op;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final meta = op['metadata'] as Map<String, dynamic>? ?? {};
    final tgChatId = meta['telegram_chat_id'] as String?;
    final hasTgLinked = tgChatId != null && tgChatId.isNotEmpty;
    final operatorId = op['id'] as String? ?? '';

    final flows = (op['flows'] as List? ?? []).map((f) {
      if (f is Map) return Map<String, dynamic>.from(f);
      return <String, dynamic>{'id': f.toString()};
    }).toList();

    if (flows.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined,
                size: 48, color: AppColors.ctText3),
            SizedBox(height: 12),
            Text('Sin flujos asignados',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppColors.ctText2)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: flows
            .map((f) => _FlowCard(
                  flow: f,
                  operatorId: operatorId,
                  hasTgLinked: hasTgLinked,
                ))
            .toList(),
      ),
    );
  }
}

class _FlowCard extends StatefulWidget {
  const _FlowCard({
    required this.flow,
    required this.operatorId,
    required this.hasTgLinked,
  });
  final Map<String, dynamic> flow;
  final String operatorId;
  final bool hasTgLinked;

  @override
  State<_FlowCard> createState() => _FlowCardState();
}

class _FlowCardState extends State<_FlowCard> {
  bool _sending = false;

  Future<void> _sendInvite() async {
    setState(() => _sending = true);
    final channelId =
        widget.flow['channel_id'] as String? ??
        widget.flow['id'] as String? ?? '';
    try {
      await OperatorsApi.sendTelegramInvite(
        operatorId: widget.operatorId,
        channelId: channelId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invitación enviada'),
          backgroundColor: AppColors.ctOk,
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error al enviar la invitación'),
          backgroundColor: AppColors.ctDanger,
        ));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final flow = widget.flow;
    final name =
        flow['name'] as String? ?? flow['id'] as String? ?? '—';
    final channelTypes = flow['channel_types'];
    final isTelegram =
        channelTypes is List && channelTypes.contains('telegram');
    final isWa =
        channelTypes is List && channelTypes.contains('whatsapp');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Canal icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isTelegram
                  ? const Color(0xFFE8F4FD)
                  : AppColors.ctOkBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTelegram ? Icons.telegram : Icons.chat_bubble_outline,
              size: 16,
              color: isTelegram
                  ? const Color(0xFF0088CC)
                  : AppColors.ctOk,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctText,
                    )),
                const SizedBox(height: 2),
                Text(
                  isTelegram
                      ? 'Telegram'
                      : isWa
                          ? 'WhatsApp'
                          : 'Canal',
                  style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctText2),
                ),
              ],
            ),
          ),
          // Telegram link badge / invite button
          if (isTelegram && !widget.hasTgLinked) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.ctRedBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text('Sin vincular',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ctRedText,
                  )),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFE8F4FD),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: _sending ? null : _sendInvite,
                child: _sending
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enviar invitación',
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0088CC),
                        )),
              ),
            ),
          ] else if (isTelegram && widget.hasTgLinked) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.ctOkBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: AppColors.ctOk),
                  SizedBox(width: 4),
                  Text('Vinculado',
                      style: TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctOkText,
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tab PERMISOS ───────────────────────────────────────────────────────────────

class _PermisosTab extends StatelessWidget {
  const _PermisosTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline, size: 56, color: AppColors.ctText3),
            SizedBox(height: 16),
            Text(
              'La asignación de permisos individuales por operador '
              'estará disponible próximamente',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 15,
                color: AppColors.ctText2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab HISTORIAL ──────────────────────────────────────────────────────────────

class _HistorialTab extends StatefulWidget {
  const _HistorialTab({required this.operatorId});
  final String operatorId;

  @override
  State<_HistorialTab> createState() => _HistorialTabState();
}

class _HistorialTabState extends State<_HistorialTab> {
  List<Map<String, dynamic>>? _sessions;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance
          .get('/operators/${widget.operatorId}/sessions');
      final data = res.data;
      final List raw = data is List
          ? data
          : (data is Map
              ? (data['sessions'] ?? data['items'] ?? [])
              : []) as List;
      if (mounted) {
        setState(() {
          _sessions =
              raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _sessions = []; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final sessions = _sessions ?? [];
    if (sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 56, color: AppColors.ctText3),
            SizedBox(height: 16),
            Text('Sin actividad registrada',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 15,
                    color: AppColors.ctText2)),
            SizedBox(height: 6),
            Text('El historial de sesiones estará disponible próximamente',
                style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText3)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: sessions.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, color: AppColors.ctBorder),
      itemBuilder: (context, i) {
        final s = sessions[i];
        final flowName =
            s['flow_name'] as String? ?? s['flow_id'] as String? ?? '—';
        final sessionStatus = s['status'] as String? ?? '—';
        final startedAt =
            s['started_at'] as String? ?? s['created_at'] as String?;
        final isCompleted = sessionStatus == 'completed';
        return ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(flowName,
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          subtitle: Text(_fmtDate(startedAt),
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2)),
          trailing: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.ctOkBg : AppColors.ctSurface2,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(sessionStatus,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: isCompleted
                      ? AppColors.ctOkText
                      : AppColors.ctText2,
                )),
          ),
          children: [_SessionFields(session: s)],
        );
      },
    );
  }
}

class _SessionFields extends StatelessWidget {
  const _SessionFields({required this.session});
  final Map<String, dynamic> session;

  @override
  Widget build(BuildContext context) {
    final fields = session['captured_fields'] as Map<String, dynamic>? ??
        session['fields'] as Map<String, dynamic>? ??
        {};
    if (fields.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12, left: 16),
        child: Text('Sin campos capturados',
            style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.ctText3)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: fields.entries
            .map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${e.key}: ',
                          style: const TextStyle(
                              fontFamily: 'Geist',
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      Expanded(
                        child: Text(e.value.toString(),
                            style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 12,
                                color: AppColors.ctText2)),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  const _ConfirmDialog({
    required this.title,
    required this.body,
    required this.confirmLabel,
    required this.confirmColor,
  });
  final String title;
  final String body;
  final String confirmLabel;
  final Color confirmColor;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.ctSurface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(title,
          style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText)),
      content: Text(body,
          style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: AppColors.ctText2)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar',
              style:
                  TextStyle(fontFamily: 'Geist', color: AppColors.ctText2)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel,
              style: TextStyle(
                  fontFamily: 'Geist',
                  fontWeight: FontWeight.w600,
                  color: confirmColor)),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
    this.success = false,
  });
  final IconData icon;
  final String label;
  final bool danger;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.ctDanger
        : success
            ? AppColors.ctOk
            : AppColors.ctText;
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label,
            style: TextStyle(
                fontFamily: 'Geist', fontSize: 14, color: color)),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.ctText2,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontFamily: 'Geist', fontSize: 11, color: AppColors.ctText2));
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(label),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: AppColors.ctText)),
        ],
      ),
    );
  }
}
