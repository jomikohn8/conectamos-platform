import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/escalaciones_api.dart';
import '../../../core/providers/escalaciones_provider.dart';
import '../../../core/providers/permissions_provider.dart';
import '../../../core/providers/tenant_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'escalacion_list_tile.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _timeAgo(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  try {
    final dt   = DateTime.parse(raw).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1)  return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes}m';
    if (diff.inHours < 24)   return 'hace ${diff.inHours}h';
    if (diff.inDays < 7)     return 'hace ${diff.inDays}d';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d/$m/${dt.year}';
  } catch (_) {
    return '';
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
    if (s != null) return 'Error $s al procesar la solicitud';
  }
  return e.toString();
}

// ── Detail sheet ──────────────────────────────────────────────────────────────

class EscalacionDetailSheet extends ConsumerStatefulWidget {
  const EscalacionDetailSheet({
    super.key,
    required this.escalacion,
    required this.onActionDone,
    required this.onClose,
  });

  final Map<String, dynamic> escalacion;
  final VoidCallback onActionDone;
  final VoidCallback onClose;

  @override
  ConsumerState<EscalacionDetailSheet> createState() =>
      _EscalacionDetailSheetState();
}

class _EscalacionDetailSheetState
    extends ConsumerState<EscalacionDetailSheet> {
  List<Map<String, dynamic>> _triggerMessages = [];
  bool _loadingMessages = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadTriggerMessages();
  }

  @override
  void didUpdateWidget(EscalacionDetailSheet old) {
    super.didUpdateWidget(old);
    if (old.escalacion['id'] != widget.escalacion['id']) {
      _loadTriggerMessages();
    }
  }

  Future<void> _loadTriggerMessages() async {
    setState(() {
      _loadingMessages = true;
      _triggerMessages = [];
    });
    final tenantId = ref.read(activeTenantIdProvider);
    final raw = widget.escalacion['trigger_messages'];
    final ids = <String>[];
    if (raw is List) {
      for (final v in raw) {
        if (v is String) ids.add(v);
      }
    }
    if (ids.isEmpty) {
      if (mounted) setState(() => _loadingMessages = false);
      return;
    }
    try {
      final msgs = await EscalacionesApi.fetchTriggerMessages(
        ids,
        tenantId: tenantId,
      );
      if (!mounted) return;
      setState(() {
        _triggerMessages = msgs;
        _loadingMessages = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMessages = false);
    }
  }

  Future<void> _doAction(
    String action, {
    String? assignedTo,
    String? resolutionNotes,
  }) async {
    setState(() => _submitting = true);
    try {
      await EscalacionesApi.patch(
        widget.escalacion['id'] as String,
        action: action,
        assignedTo: assignedTo,
        resolutionNotes: resolutionNotes,
      );
      if (!mounted) return;
      widget.onActionDone();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  Future<void> _showAssignDialog() async {
    final tenantUsers =
        ref.read(tenantUsersForEscalacionesProvider).valueOrNull ?? [];
    if (tenantUsers.isEmpty) return;

    String? selectedUserId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDs) => AlertDialog(
          title: const Text(
            'Asignar escalación',
            style: TextStyle(
              fontFamily: 'Onest',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ctText,
            ),
          ),
          content: SizedBox(
            width: 320,
            child: DropdownButtonFormField<String>(
              key:          ValueKey(selectedUserId),
              initialValue: selectedUserId,
              hint: const Text('Seleccionar usuario'),
              decoration: const InputDecoration(
                labelText: 'Asignar a',
                filled: true,
                fillColor: AppColors.ctSurface2,
              ),
              items: tenantUsers.map((u) {
                final id   = u['id']    as String?
                    ?? u['user_id'] as String? ?? '';
                final name = u['name']  as String?
                    ?? u['email'] as String? ?? id;
                return DropdownMenuItem<String>(
                  value: id,
                  child: Text(
                    name,
                    style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) => setDs(() => selectedUserId = v),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: selectedUserId != null
                  ? () => Navigator.pop(ctx, true)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.ctTeal,
                foregroundColor: AppColors.ctNavy,
              ),
              child: const Text('Asignar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && selectedUserId != null) {
      await _doAction('assign', assignedTo: selectedUserId);
    }
  }

  Future<void> _showResolveDialog() async {
    String notes = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ResolveDialog(
        onNotesChanged: (v) => notes = v,
      ),
    );

    if (confirmed == true) {
      await _doAction(
        'resolve',
        resolutionNotes: notes.trim().isEmpty ? null : notes.trim(),
      );
    }
  }

  Future<void> _showReopenDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Reabrir escalación',
          style: TextStyle(
            fontFamily: 'Onest',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.ctText,
          ),
        ),
        content: const Text(
          '¿Confirmas que deseas reabrir esta escalación?',
          style: TextStyle(fontFamily: 'Geist', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctWarn,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _doAction('reopen');
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final esc      = widget.escalacion;
    final status   = esc['status'] as String? ?? '';
    final canManage = hasPermission(ref, 'escalations', 'manage');

    return Container(
      width: 420,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(left: BorderSide(color: AppColors.ctBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(esc, status),
          const Divider(height: 1, color: AppColors.ctBorder),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfo(esc),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.ctBorder),
                  const SizedBox(height: 16),
                  _buildStepper(esc, status),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.ctBorder),
                  const SizedBox(height: 16),
                  _buildTriggerMessages(),
                  if (status == 'resolved') ...[
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.ctBorder),
                    const SizedBox(height: 16),
                    _buildResolutionNotes(esc),
                  ],
                ],
              ),
            ),
          ),
          if (canManage) ...[
            const Divider(height: 1, color: AppColors.ctBorder),
            _buildActions(status),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> esc, String status) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.ctWarn,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Escalación',
              style: const TextStyle(
                fontFamily: 'Onest',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.ctText,
              ),
            ),
          ),
          EscalacionStatusChip(status: status),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: AppColors.ctText2,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(Map<String, dynamic> esc) {
    final op = esc['operator'];
    final operatorName = op is Map
        ? (op['name'] as String? ?? op['email'] as String? ?? '—')
        : (esc['operator_name'] as String? ?? '—');

    final flowExecutionId = esc['flow_execution_id'] as String? ?? '—';
    final flowName        = esc['flow_name'] as String?;
    final reason          = esc['reason'] as String? ?? '—';
    final workerCanResume = esc['worker_can_resume'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('INFORMACIÓN'),
        const SizedBox(height: 8),
        _infoRow('Operador', operatorName),
        _infoRow('Razón', reason),
        _infoRow(
          'Flujo',
          flowName ??
              (flowExecutionId.length > 8
                  ? '…${flowExecutionId.substring(flowExecutionId.length - 8)}'
                  : flowExecutionId),
          tooltip: flowExecutionId,
        ),
        _infoRow(
          'Worker puede reanudar',
          workerCanResume ? 'Sí' : 'No',
          valueColor: workerCanResume ? AppColors.ctOkText : AppColors.ctText2,
        ),
      ],
    );
  }

  Widget _buildStepper(Map<String, dynamic> esc, String status) {
    final steps = [
      _StepInfo(
        label: 'Abierta',
        done: true,
        date: esc['opened_at'] as String?,
      ),
      _StepInfo(
        label: 'Asignada',
        done: status == 'assigned' || status == 'resolved' || status == 'reopened',
        date: esc['assigned_at'] as String?,
        subtitle: _resolveAssigneeName(esc),
      ),
      _StepInfo(
        label: 'Resuelta',
        done: status == 'resolved',
        date: esc['resolved_at'] as String?,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('PROGRESO'),
        const SizedBox(height: 8),
        ...steps.asMap().entries.map((entry) {
          final i    = entry.key;
          final step = entry.value;
          final isLast = i == steps.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circle + connector
              SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: step.done
                            ? AppColors.ctOk
                            : AppColors.ctSurface2,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: step.done
                              ? AppColors.ctOk
                              : AppColors.ctBorder2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: step.done
                          ? const Icon(Icons.check, size: 11, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontFamily: 'Geist',
                                fontSize: 10,
                                color: AppColors.ctText3,
                              ),
                            ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 32,
                        color: step.done ? AppColors.ctOk : AppColors.ctBorder,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 2,
                    bottom: isLast ? 0 : 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.label,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: step.done
                              ? AppColors.ctText
                              : AppColors.ctText3,
                        ),
                      ),
                      if (step.date != null && step.date!.isNotEmpty)
                        Text(
                          _timeAgo(step.date),
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            color: AppColors.ctText3,
                          ),
                        ),
                      if (step.subtitle != null && step.subtitle!.isNotEmpty)
                        Text(
                          step.subtitle!,
                          style: const TextStyle(
                            fontFamily: 'Geist',
                            fontSize: 11,
                            color: AppColors.ctText2,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTriggerMessages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('MENSAJES DISPARADORES'),
        const SizedBox(height: 8),
        if (_loadingMessages)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.ctTeal,
              ),
            ),
          )
        else if (_triggerMessages.isEmpty)
          const Text(
            'Sin mensajes disparadores.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 12,
              color: AppColors.ctText3,
            ),
          )
        else
          ..._triggerMessages.map((msg) => _MessageBubble(msg: msg)),
      ],
    );
  }

  Widget _buildResolutionNotes(Map<String, dynamic> esc) {
    final notes = esc['resolution_notes'] as String?;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('NOTAS DE RESOLUCIÓN'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.ctOkBg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctOk.withValues(alpha: 0.3)),
          ),
          child: Text(
            notes?.isNotEmpty == true ? notes! : '—',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctOkText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(String status) {
    if (_submitting) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.ctTeal,
          ),
        ),
      );
    }

    final buttons = <Widget>[];

    if (status == 'open') {
      buttons.add(_ActionButton(
        label: 'Asignar',
        icon: Icons.person_add_outlined,
        color: AppColors.ctTeal,
        onTap: _showAssignDialog,
      ));
    }

    if (status == 'assigned') {
      buttons.add(_ActionButton(
        label: 'Resolver',
        icon: Icons.check_circle_outline_rounded,
        color: AppColors.ctOk,
        onTap: _showResolveDialog,
      ));
    }

    if (status == 'resolved') {
      buttons.add(_ActionButton(
        label: 'Reabrir',
        icon: Icons.refresh_rounded,
        color: AppColors.ctWarn,
        onTap: _showReopenDialog,
      ));
    }

    if (buttons.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: buttons
            .expand((b) => [b, const SizedBox(width: 8)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  // ── Utils ──────────────────────────────────────────────────────────────────

  String? _resolveAssigneeName(Map<String, dynamic> esc) {
    final u = esc['assigned_to_user'];
    if (u is Map) {
      final name = u['name'] as String? ?? u['email'] as String?;
      if (name != null) return 'Asignado a: $name';
    }
    if (esc['assigned_to'] != null) return 'Asignado';
    return null;
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppColors.ctText3,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    Color? valueColor,
    String? tooltip,
  }) {
    final valueWidget = Text(
      value,
      style: TextStyle(
        fontFamily: 'Geist',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: valueColor ?? AppColors.ctText,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText2,
            ),
          ),
          const Spacer(),
          tooltip != null
              ? Tooltip(message: tooltip, child: valueWidget)
              : valueWidget,
        ],
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _StepInfo {
  const _StepInfo({
    required this.label,
    required this.done,
    this.date,
    this.subtitle,
  });
  final String  label;
  final bool    done;
  final String? date;
  final String? subtitle;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.msg});
  final Map<String, dynamic> msg;

  @override
  Widget build(BuildContext context) {
    final isOutbound  = (msg['direction'] as String?) == 'outbound';
    final body        = msg['raw_body'] as String? ?? '—';
    final fromName    = msg['from_name'] as String? ?? '';
    final receivedAt  = msg['received_at'] as String?;

    return Align(
      alignment: isOutbound ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isOutbound ? AppColors.ctTealLight : AppColors.ctSurface2,
          borderRadius: BorderRadius.only(
            topLeft:     const Radius.circular(12),
            topRight:    const Radius.circular(12),
            bottomLeft:  isOutbound ? const Radius.circular(12) : Radius.zero,
            bottomRight: isOutbound ? Radius.zero : const Radius.circular(12),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isOutbound ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (fromName.isNotEmpty)
              Text(
                fromName,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ctTealDark,
                ),
              ),
            Text(
              body,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.ctText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _timeAgo(receivedAt),
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 10,
                color: AppColors.ctText3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final String   label;
  final IconData icon;
  final Color    color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        textStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
    );
  }
}

// ── Resolve dialog ────────────────────────────────────────────────────────────

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog({required this.onNotesChanged});
  final ValueChanged<String> onNotesChanged;

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Resolver escalación',
        style: TextStyle(
          fontFamily: 'Onest',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.ctText,
        ),
      ),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _ctrl,
          onChanged: widget.onNotesChanged,
          maxLines: 4,
          style: const TextStyle(fontFamily: 'Geist', fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'Notas de resolución (opcional)',
            filled: true,
            fillColor: AppColors.ctSurface2,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.ctOk,
            foregroundColor: Colors.white,
          ),
          child: const Text('Resolver'),
        ),
      ],
    );
  }
}
