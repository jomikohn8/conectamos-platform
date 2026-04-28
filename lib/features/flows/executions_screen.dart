import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/api/flows_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

String _formatDate(String? raw) {
  if (raw == null) return '';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(dt.year, dt.month, dt.day);
    final time = DateFormat('HH:mm').format(dt);
    if (day == today) return 'Hoy $time';
    if (day == yesterday) return 'Ayer $time';
    return '${DateFormat('dd MMM').format(dt)} · $time';
  } catch (_) {
    return raw;
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

// ── Screen ────────────────────────────────────────────────────────────────────

class ExecutionsScreen extends ConsumerStatefulWidget {
  const ExecutionsScreen({super.key});

  @override
  ConsumerState<ExecutionsScreen> createState() => _ExecutionsScreenState();
}

class _ExecutionsScreenState extends ConsumerState<ExecutionsScreen> {
  List<Map<String, dynamic>> _executions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final data = await FlowsApi.listPendingExecutions(tenantId: tenantId);
      if (!mounted) return;
      setState(() {
        _executions = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _dioError(e);
        _loading = false;
      });
    }
  }

  void _openExecutionDetail(Map<String, dynamic> execution) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.ctSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _ExecutionDetailSheet(
        execution: execution,
        onSubmitted: _load,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter bar / header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              const Text(
                'Tareas pendientes',
                style: TextStyle(
                  fontFamily: 'Onest',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ctText,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    size: 20, color: AppColors.ctText2),
                tooltip: 'Actualizar',
                onPressed: _load,
              ),
            ],
          ),
        ),

        // Body
        if (_loading)
          const Expanded(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.ctTeal),
            ),
          )
        else if (_error != null)
          Expanded(
            child: _ErrorState(message: _error!, onRetry: _load),
          )
        else if (_executions.isEmpty)
          const Expanded(child: _EmptyState())
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              itemCount: _executions.length,
              separatorBuilder: (context2, i) => const SizedBox(height: 8),
              itemBuilder: (context2, i) => _ExecutionCard(
                execution: _executions[i],
                onTap: () => _openExecutionDetail(_executions[i]),
              ),
            ),
          ),
      ],
    );
  }
}

// ── _EmptyState ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.task_alt, size: 48, color: AppColors.ctText3),
          const SizedBox(height: 12),
          const Text(
            'No hay tareas pendientes',
            style: TextStyle(
              fontFamily: 'Onest',
              fontSize: 16,
              color: AppColors.ctText2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Las ejecuciones que requieren tu atención aparecerán aquí.',
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── _ErrorState ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AppColors.ctDanger),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(color: AppColors.ctTeal)),
          ),
        ],
      ),
    );
  }
}

// ── _StatusChip ───────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      'pending_dashboard' => (
          AppColors.ctWarnBg,
          AppColors.ctWarnText,
          'Pendiente',
        ),
      'in_progress' => (
          AppColors.ctInfoBg,
          AppColors.ctInfoText,
          'En curso',
        ),
      _ => (AppColors.ctSurface2, AppColors.ctText2, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ── _ExecutionCard ────────────────────────────────────────────────────────────

class _ExecutionCard extends StatelessWidget {
  const _ExecutionCard({
    required this.execution,
    required this.onTap,
  });

  final Map<String, dynamic> execution;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = execution['flow_name'] as String? ??
        execution['flow_slug'] as String? ??
        '—';
    final status = execution['status'] as String? ?? '';
    final createdAt = execution['created_at'] as String?;
    final fieldValues = execution['field_values'];
    final fieldCount =
        fieldValues is List ? fieldValues.length : 0;

    return Card(
      elevation: 0,
      color: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Onest',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ctText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(createdAt),
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 12,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(status: status),
                  if (fieldCount > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '$fieldCount campos',
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 11,
                        color: AppColors.ctText3,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _ExecutionDetailSheet ─────────────────────────────────────────────────────

class _ExecutionDetailSheet extends ConsumerStatefulWidget {
  const _ExecutionDetailSheet({
    required this.execution,
    required this.onSubmitted,
  });

  final Map<String, dynamic> execution;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<_ExecutionDetailSheet> createState() =>
      _ExecutionDetailSheetState();
}

class _ExecutionDetailSheetState
    extends ConsumerState<_ExecutionDetailSheet> {
  Map<String, dynamic>? _detail;
  bool _loadingDetail = true;
  bool _submitting = false;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    for (final ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDetail() async {
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final executionId = widget.execution['id'] as String;
      final detail = await FlowsApi.getExecution(
        tenantId: tenantId,
        executionId: executionId,
      );
      if (!mounted) return;

      // Build controllers for capturable fields (source != 'inherited')
      final fieldValues = detail['field_values'];
      if (fieldValues is List) {
        for (final f in fieldValues.whereType<Map>()) {
          final source = f['source'] as String?;
          final fieldId = f['field_id'] as String?;
          if (source != 'inherited' && fieldId != null) {
            _controllers[fieldId] = TextEditingController();
          }
        }
      }

      setState(() {
        _detail = detail;
        _loadingDetail = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetail = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
      ));
    }
  }

  Future<void> _submit() async {
    final detail = _detail;
    if (detail == null) return;

    // Validate required fields
    final fieldValues = detail['field_values'];
    if (fieldValues is List) {
      for (final f in fieldValues.whereType<Map>()) {
        final source = f['source'] as String?;
        final fieldId = f['field_id'] as String?;
        final required = f['required'] as bool? ?? false;
        if (source != 'inherited' && fieldId != null && required) {
          final ctrl = _controllers[fieldId];
          if (ctrl != null && ctrl.text.trim().isEmpty) {
            final label = f['label'] as String? ?? fieldId;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('El campo "$label" es requerido'),
              backgroundColor: AppColors.ctWarn,
            ));
            return;
          }
        }
      }
    }

    setState(() => _submitting = true);
    try {
      final executionId = widget.execution['id'] as String;
      final payload = _controllers.entries
          .map((e) => {'field_id': e.key, 'value': e.value.text.trim()})
          .toList();
      await FlowsApi.submitExecution(
        executionId: executionId,
        fieldValues: payload,
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmitted();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tarea enviada'),
        backgroundColor: AppColors.ctOk,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_dioError(e)),
        backgroundColor: AppColors.ctDanger,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ctBorder2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          if (_loadingDetail)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.ctTeal),
              ),
            )
          else
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: _buildContent(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final detail = _detail;
    if (detail == null) return const SizedBox.shrink();

    final flowName = detail['flow_name'] as String? ??
        widget.execution['flow_name'] as String? ??
        '—';
    final inheritedRaw = detail['inherited_fields'];
    final inheritedFields =
        inheritedRaw is List ? List<Map>.from(inheritedRaw.whereType<Map>()) : <Map>[];
    final hasInherited = inheritedFields.isNotEmpty;
    final fieldValues = detail['field_values'];
    final captureFields = fieldValues is List
        ? fieldValues
            .whereType<Map>()
            .where((f) => f['source'] != 'inherited')
            .toList()
        : <Map>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          flowName,
          style: const TextStyle(
            fontFamily: 'Onest',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 8),

        // Inherited fields
        if (hasInherited) ...[
          const Text(
            'INFORMACIÓN HEREDADA',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.ctText3,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          ...inheritedFields.map((f) {
            final label = f['label'] as String? ?? f['field_id'] ?? '—';
            final value = f['value']?.toString() ?? '—';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ctText,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(color: AppColors.ctBorder),
          const SizedBox(height: 12),
        ],

        // Fields to capture
        const Text(
          'CAMPOS A COMPLETAR',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.ctText3,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),

        if (captureFields.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Sin campos adicionales',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctText3,
              ),
            ),
          )
        else
          ...captureFields.map((f) {
            final fieldId = f['field_id'] as String? ?? '';
            final label = f['label'] as String? ?? fieldId;
            final ctrl = _controllers[fieldId] ?? TextEditingController();
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: TextField(
                controller: ctrl,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: AppColors.ctText2,
                  ),
                  filled: true,
                  fillColor: AppColors.ctSurface2,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.ctBorder2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppColors.ctBorder2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.ctTeal),
                  ),
                ),
              ),
            );
          }),

        const SizedBox(height: 24),

        // Submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ctTeal,
              foregroundColor: AppColors.ctNavy,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Enviar',
                    style: TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
