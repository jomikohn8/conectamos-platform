import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final _bcastOperatorsProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return [];
    final res = await ApiClient.instance.get(
      '/operators',
      queryParameters: {'tenant_id': tenantId},
    );
    final data = res.data;
    final List raw = data is List ? data : [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  },
);

final _bcastTemplatesProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return [];
    final res = await ApiClient.instance.get(
      '/templates',
      queryParameters: {'tenant_id': tenantId, 'status': 'APPROVED'},
    );
    final data = res.data;
    final List raw = data is List ? data : (data['items'] ?? data['templates'] ?? []) as List;
    return raw
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((t) =>
            (t['status']?.toString().toUpperCase() ?? '') == 'APPROVED')
        .toList();
  },
);

final _bcastHistoryProvider =
    FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return [];
    try {
      final res = await ApiClient.instance.get(
        '/broadcasts',
        queryParameters: {'tenant_id': tenantId},
      );
      final data = res.data;
      final List raw = data is List ? data : (data['items'] ?? []) as List;
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  },
);

// ── Helper: resuelve preview de plantilla ─────────────────────────────────────

String _resolvePreview(Map<String, dynamic> template) {
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

List<String> _resolveTemplateVariables(Map<String, dynamic> template) {
  const examples = <String, String>{
    'nombre_operador':   'José Miguel',
    'telefono_operador': '5215559537449',
    'nombre_tenant':     'TMR-Prixz',
    'fecha_hoy':         '14/04/2026',
    'hora_actual':       '10:30 AM',
  };
  final vars = template['variables'];
  if (vars is! List || vars.isEmpty) return [];
  final sorted = vars
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList()
    ..sort((a, b) =>
        ((a['slot'] as int?) ?? 0).compareTo((b['slot'] as int?) ?? 0));
  return sorted.map((v) {
    final type = v['type'] as String? ?? 'free';
    final key  = v['key']  as String? ?? '';
    if (type == 'system') return examples[key] ?? '[$key]';
    return key.isNotEmpty ? '[$key]' : '[variable]';
  }).toList();
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  // Mensaje
  bool _useTemplate = false;
  final _msgCtrl = TextEditingController();
  String? _selectedTemplateId;

  // Filtros destinatarios
  final _selectedStatuses = <String>{'active'};
  final _selectedFlows = <String>{};

  // Estado envío
  bool _sending = false;
  bool _confirming = false;
  String? _result;

  // Historial
  bool _showHistory = false;

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterOperators(
      List<Map<String, dynamic>> operators) {
    return operators.where((op) {
      final status = op['status']?.toString() ?? 'active';
      if (_selectedStatuses.isNotEmpty && !_selectedStatuses.contains(status)) {
        return false;
      }
      if (_selectedFlows.isNotEmpty) {
        final flows = op['flows'];
        final opFlows = flows is List
            ? flows.map((f) => f.toString()).toSet()
            : <String>{};
        if (opFlows.intersection(_selectedFlows).isEmpty) return false;
      }
      return true;
    }).toList();
  }

  bool get _canSend {
    if (_useTemplate) return _selectedTemplateId != null;
    return _msgCtrl.text.trim().isNotEmpty;
  }

  Future<void> _sendBroadcast(
      List<Map<String, dynamic>> filtered,
      List<Map<String, dynamic>> templates) async {
    setState(() { _sending = true; _result = null; });
    try {
      final userId =
          Supabase.instance.client.auth.currentUser?.id ?? '';
      final tenantId = ref.read(activeTenantIdProvider);

      Map<String, dynamic>? selectedTemplate;
      if (_useTemplate && _selectedTemplateId != null) {
        selectedTemplate = templates.firstWhere(
          (t) => t['id']?.toString() == _selectedTemplateId,
          orElse: () => {},
        );
      }

      final body = <String, dynamic>{
        'tenant_id':          tenantId,
        'sent_by_user_id':    userId,
        'message_text':       _useTemplate ? null : _msgCtrl.text.trim(),
        'template_id':        _useTemplate ? _selectedTemplateId : null,
        'template_variables': _useTemplate && selectedTemplate != null
            ? _resolveTemplateVariables(selectedTemplate)
            : <String>[],
        'segment_filters': {
          'status': _selectedStatuses.toList(),
          'flows':  _selectedFlows.toList(),
        },
      };

      final res = await ApiClient.instance.post(
        '/broadcasts',
        data: body,
        options: Options(
            validateStatus: (s) => s != null && s >= 200 && s < 300),
      );

      final d          = res.data is Map ? res.data as Map : {};
      final sentCount  = d['sent_count']      ?? d['sent']       ?? 0;
      final failedCount = d['failed_count']   ?? d['failed']     ?? 0;
      final total      = d['recipient_count'] ?? d['total']      ?? filtered.length;

      if (!mounted) return;
      final resultMsg = failedCount > 0
          ? 'Enviado a $sentCount de $total operadores. $failedCount fallaron.'
          : 'Enviado a $sentCount de $total operadores.';
      setState(() {
        _sending    = false;
        _confirming = false;
        _result     = resultMsg;
      });
      ref.invalidate(_bcastHistoryProvider(tenantId));
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _sending    = false;
        _confirming = false;
        _result     = 'Error: ${detail ?? e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _sending = false; _confirming = false; _result = 'Error: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantId      = ref.watch(activeTenantIdProvider);
    final operatorsAsync = ref.watch(_bcastOperatorsProvider(tenantId));
    final templatesAsync = ref.watch(_bcastTemplatesProvider(tenantId));

    final operators = operatorsAsync.valueOrNull ?? [];
    final templates = templatesAsync.valueOrNull ?? [];
    final filtered  = _filterOperators(operators);

    // Unique flows across all operators
    final allFlows = <String>{};
    for (final op in operators) {
      final f = op['flows'];
      if (f is List) {
        for (final fl in f) {
          allFlows.add(fl.toString());
        }
      }
    }

    // Operators with closed window (no inbound in 24h) — best effort from data
    final closedWindowCount = _useTemplate
        ? 0
        : filtered.where((op) {
            final last = op['last_inbound_at'] as String?;
            if (last == null) return true;
            final dt = DateTime.tryParse(last);
            if (dt == null) return true;
            return DateTime.now().toUtc().difference(dt.toUtc()).inHours >= 24;
          }).length;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        _BroadcastHeader(onClose: () => context.go('/conversations')),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 760;
              final formWidget = _FormColumn(
                useTemplate: _useTemplate,
                msgCtrl: _msgCtrl,
                templates: templates,
                selectedTemplateId: _selectedTemplateId,
                closedWindowCount: closedWindowCount,
                filteredCount: filtered.length,
                selectedStatuses: _selectedStatuses,
                selectedFlows: _selectedFlows,
                allFlows: allFlows,
                canSend: _canSend,
                sending: _sending,
                confirming: _confirming,
                result: _result,
                onToggleMode: (v) => setState(() {
                  _useTemplate = v;
                  _selectedTemplateId = null;
                  _result = null;
                }),
                onSelectTemplate: (id) =>
                    setState(() { _selectedTemplateId = id; _result = null; }),
                onToggleStatus: (s) => setState(() {
                  if (_selectedStatuses.contains(s)) {
                    _selectedStatuses.remove(s);
                  } else {
                    _selectedStatuses.add(s);
                  }
                  _result = null;
                }),
                onToggleFlow: (f) => setState(() {
                  if (_selectedFlows.contains(f)) {
                    _selectedFlows.remove(f);
                  } else {
                    _selectedFlows.add(f);
                  }
                  _result = null;
                }),
                onSend: (!_canSend || filtered.isEmpty || _sending)
                    ? null
                    : () => setState(() { _confirming = true; }),
                onConfirm: () => _sendBroadcast(filtered, templates),
                onCancelConfirm: () => setState(() => _confirming = false),
              );

              final selectedTemplate = _useTemplate && _selectedTemplateId != null
                  ? templates.cast<Map<String, dynamic>?>().firstWhere(
                      (t) => t!['id']?.toString() == _selectedTemplateId,
                      orElse: () => null)
                  : null;

              final previewWidget = _PreviewColumn(
                useTemplate: _useTemplate,
                msgCtrl: _msgCtrl,
                selectedTemplate: selectedTemplate,
                filtered: filtered,
              );

              if (wide) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: formWidget),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: previewWidget),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _HistorySection(
                        tenantId: tenantId,
                        show: _showHistory,
                        onToggle: () =>
                            setState(() => _showHistory = !_showHistory),
                      ),
                    ],
                  ),
                );
              } else {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      formWidget,
                      const SizedBox(height: 20),
                      previewWidget,
                      const SizedBox(height: 24),
                      _HistorySection(
                        tenantId: tenantId,
                        show: _showHistory,
                        onToggle: () =>
                            setState(() => _showHistory = !_showHistory),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _BroadcastHeader extends StatelessWidget {
  const _BroadcastHeader({required this.onClose});
  final VoidCallback onClose;

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
                  'Nuevo broadcast',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Envía un mensaje masivo a tus operadores',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _CloseButton(onTap: onClose),
        ],
      ),
    );
  }
}

class _CloseButton extends StatefulWidget {
  const _CloseButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CloseButton> createState() => _CloseButtonState();
}

class _CloseButtonState extends State<_CloseButton> {
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 18,
            color: AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}

// ── Columna izquierda: formulario ─────────────────────────────────────────────

class _FormColumn extends StatelessWidget {
  const _FormColumn({
    required this.useTemplate,
    required this.msgCtrl,
    required this.templates,
    required this.selectedTemplateId,
    required this.closedWindowCount,
    required this.filteredCount,
    required this.selectedStatuses,
    required this.selectedFlows,
    required this.allFlows,
    required this.canSend,
    required this.sending,
    required this.confirming,
    required this.result,
    required this.onToggleMode,
    required this.onSelectTemplate,
    required this.onToggleStatus,
    required this.onToggleFlow,
    required this.onSend,
    required this.onConfirm,
    required this.onCancelConfirm,
  });

  final bool useTemplate;
  final TextEditingController msgCtrl;
  final List<Map<String, dynamic>> templates;
  final String? selectedTemplateId;
  final int closedWindowCount;
  final int filteredCount;
  final Set<String> selectedStatuses;
  final Set<String> selectedFlows;
  final Set<String> allFlows;
  final bool canSend;
  final bool sending;
  final bool confirming;
  final String? result;
  final ValueChanged<bool> onToggleMode;
  final ValueChanged<String?> onSelectTemplate;
  final ValueChanged<String> onToggleStatus;
  final ValueChanged<String> onToggleFlow;
  final VoidCallback? onSend;
  final VoidCallback onConfirm;
  final VoidCallback onCancelConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sección Mensaje ────────────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(label: 'Mensaje'),
              const SizedBox(height: 14),

              // Toggle segmentado
              _ModeToggle(
                useTemplate: useTemplate,
                onChanged: onToggleMode,
              ),
              const SizedBox(height: 16),

              if (!useTemplate) ...[
                // Texto libre
                _BuildTextField(ctrl: msgCtrl),
                if (closedWindowCount > 0) ...[
                  const SizedBox(height: 10),
                  _WarningBanner(
                    message:
                        '$closedWindowCount operador${closedWindowCount > 1 ? 'es tienen' : ' tiene'} ventana de 24hrs cerrada y no recibirán este mensaje.',
                  ),
                ],
              ] else ...[
                // Selector de plantilla
                if (templates.isEmpty)
                  const Text(
                    'No hay plantillas APPROVED disponibles.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  )
                else
                  _TemplateDropdown(
                    templates: templates,
                    selectedId: selectedTemplateId,
                    onChanged: onSelectTemplate,
                  ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // ── Sección Destinatarios ──────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(label: '¿A quién enviar?'),
              const SizedBox(height: 14),

              // Status chips
              const _Label(text: 'Estado del operador'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _FilterChip(
                    label: 'Activos',
                    value: 'active',
                    selected: selectedStatuses.contains('active'),
                    onTap: onToggleStatus,
                  ),
                  _FilterChip(
                    label: 'En incidencia',
                    value: 'incident',
                    selected: selectedStatuses.contains('incident'),
                    onTap: onToggleStatus,
                  ),
                  _FilterChip(
                    label: 'Inactivos',
                    value: 'inactive',
                    selected: selectedStatuses.contains('inactive'),
                    onTap: onToggleStatus,
                  ),
                ],
              ),

              if (allFlows.isNotEmpty) ...[
                const SizedBox(height: 16),
                const _Label(text: 'Flujo asignado'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: allFlows.map((f) => _FilterChip(
                    label: f,
                    value: f,
                    selected: selectedFlows.contains(f),
                    onTap: onToggleFlow,
                  )).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Contador
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: filteredCount > 0
                      ? const Color(0xFFCCFBF1)
                      : AppColors.ctSurface2,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.group_rounded,
                      size: 14,
                      color: filteredCount > 0
                          ? AppColors.ctTeal
                          : AppColors.ctText3,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$filteredCount operador${filteredCount != 1 ? 'es' : ''} seleccionado${filteredCount != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: filteredCount > 0
                            ? AppColors.ctTeal
                            : AppColors.ctText3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ── Confirmar / Enviar ─────────────────────────────────────────────
        if (confirming) ...[
          _ConfirmBox(
            count: filteredCount,
            onConfirm: onConfirm,
            onCancel: onCancelConfirm,
            sending: sending,
          ),
          const SizedBox(height: 12),
        ] else ...[
          _SendButton(
            enabled: canSend && filteredCount > 0 && !sending,
            loading: sending,
            count: filteredCount,
            onTap: onSend,
          ),
          const SizedBox(height: 12),
        ],

        if (result != null)
          _ResultBanner(message: result!),
      ],
    );
  }
}

// ── Columna derecha: preview ──────────────────────────────────────────────────

class _PreviewColumn extends StatelessWidget {
  const _PreviewColumn({
    required this.useTemplate,
    required this.msgCtrl,
    required this.selectedTemplate,
    required this.filtered,
  });

  final bool useTemplate;
  final TextEditingController msgCtrl;
  final Map<String, dynamic>? selectedTemplate;
  final List<Map<String, dynamic>> filtered;

  @override
  Widget build(BuildContext context) {
    String previewText = '';
    if (useTemplate && selectedTemplate != null) {
      previewText = _resolvePreview(selectedTemplate!);
    } else if (!useTemplate) {
      previewText = msgCtrl.text;
    }

    final visibleOps = filtered.take(5).toList();
    final remaining  = filtered.length - visibleOps.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview burbuja
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle(label: 'Vista previa del mensaje'),
              const SizedBox(height: 12),
              if (previewText.isEmpty)
                const Text(
                  'El mensaje aparecerá aquí...',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ctText3,
                    fontStyle: FontStyle.italic,
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 320),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFD9FDD3),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(2),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      previewText,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Lista de destinatarios
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: _SectionTitle(label: 'Destinatarios'),
                  ),
                  Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctTeal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const Text(
                  'Ningún operador coincide con los filtros.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                )
              else ...[
                ...visibleOps.map((op) {
                  final name = op['display_name']?.toString() ??
                      op['name']?.toString() ?? '—';
                  final phone = op['phone']?.toString() ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            name.isNotEmpty
                                ? name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ctText2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.ctText,
                                ),
                              ),
                              if (phone.isNotEmpty)
                                Text(
                                  phone,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    color: AppColors.ctText2,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (remaining > 0)
                  Text(
                    'y $remaining más...',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctText2,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ── Sección historial ─────────────────────────────────────────────────────────

class _HistorySection extends ConsumerWidget {
  const _HistorySection({
    required this.tenantId,
    required this.show,
    required this.onToggle,
  });
  final String tenantId;
  final bool show;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_bcastHistoryProvider(tenantId));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header colapsable
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Broadcasts anteriores',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctText,
                      ),
                    ),
                  ),
                  Icon(
                    show
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.ctText2,
                  ),
                ],
              ),
            ),
          ),

          if (show) ...[
            const Divider(height: 1, color: AppColors.ctBorder),
            Padding(
              padding: const EdgeInsets.all(16),
              child: historyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(color: AppColors.ctTeal),
                  ),
                ),
                error: (e, _) => Text(
                  'Error al cargar historial: $e',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                ),
                data: (history) => history.isEmpty
                    ? const Text(
                        'No hay broadcasts enviados aún.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.ctText2,
                        ),
                      )
                    : Column(
                        children: history
                            .map((b) => _HistoryItem(broadcast: b))
                            .toList(),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  const _HistoryItem({required this.broadcast});
  final Map<String, dynamic> broadcast;

  @override
  Widget build(BuildContext context) {
    final createdAt = broadcast['created_at']?.toString() ?? '';
    DateTime? dt;
    try {
      dt = DateTime.parse(createdAt).toLocal();
    } catch (_) {}
    final dateStr = dt != null
        ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
        : createdAt;

    final sent   = broadcast['sent']   ?? broadcast['total_sent']   ?? '—';
    final failed = broadcast['failed'] ?? broadcast['total_failed'] ?? 0;
    final status = broadcast['status']?.toString() ?? 'sent';

    final msgText = broadcast['message_text']?.toString() ??
        broadcast['template_id']?.toString() ?? '';
    final preview = msgText.length > 60
        ? '${msgText.substring(0, 60)}...'
        : msgText;

    return InkWell(
      onTap: () => showDialog(
        context: context,
        builder: (_) => _BroadcastDetailDialog(broadcast: broadcast),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
              bottom: BorderSide(color: AppColors.ctBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.ctText,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    dateStr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
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
                _StatusBadge(status: status),
                const SizedBox(height: 4),
                Text(
                  '$sent enviados · $failed fallaron',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BroadcastDetailDialog extends StatelessWidget {
  const _BroadcastDetailDialog({required this.broadcast});
  final Map<String, dynamic> broadcast;

  @override
  Widget build(BuildContext context) {
    final recipients = broadcast['recipients'];
    final List<Map<String, dynamic>> recipientList =
        recipients is List
            ? recipients
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
            : [];

    final msgText = broadcast['message_text']?.toString() ?? '';

    return Dialog(
      backgroundColor: AppColors.ctSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.ctBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalle del broadcast',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctText,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: AppColors.ctText2),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (msgText.isNotEmpty) ...[
                      const Text(
                        'Mensaje',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.ctSurface2,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          msgText,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: AppColors.ctText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (recipientList.isNotEmpty) ...[
                      const Text(
                        'Destinatarios',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ctText2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...recipientList.map((r) {
                        final name =
                            r['name']?.toString() ?? r['phone']?.toString() ?? '—';
                        final rStatus = r['status']?.toString() ?? 'sent';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.ctText,
                                  ),
                                ),
                              ),
                              _StatusBadge(status: rStatus),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets locales ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});
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
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ctText,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.text});
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

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.useTemplate, required this.onChanged});
  final bool useTemplate;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleItem(
            label: 'Texto libre',
            active: !useTemplate,
            onTap: () => onChanged(false),
          ),
          _ToggleItem(
            label: 'Plantilla',
            active: useTemplate,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.ctTeal : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.ctNavy : AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}

class _BuildTextField extends StatelessWidget {
  const _BuildTextField({required this.ctrl});
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      maxLines: 5,
      minLines: 3,
      style: const TextStyle(
          fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
      decoration: InputDecoration(
        hintText: 'Escribe el mensaje que recibirán todos los operadores...',
        hintStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText3),
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
    );
  }
}

class _TemplateDropdown extends StatelessWidget {
  const _TemplateDropdown({
    required this.templates,
    required this.selectedId,
    required this.onChanged,
  });
  final List<Map<String, dynamic>> templates;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final validId =
        templates.any((t) => t['id']?.toString() == selectedId)
            ? selectedId
            : null;
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.ctBorder2),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validId,
          isExpanded: true,
          isDense: true,
          hint: const Text(
            'Selecciona una plantilla',
            style: TextStyle(
                fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText3),
          ),
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: AppColors.ctText3,
          ),
          items: templates.map((t) {
            final id   = t['id']?.toString() ?? '';
            final name = t['name']?.toString() ?? id;
            return DropdownMenuItem<String>(value: id, child: Text(name));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFCCFBF1) : AppColors.ctSurface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.ctTeal : AppColors.ctBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.ctTeal : AppColors.ctText2,
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  const _SendButton({
    required this.enabled,
    required this.loading,
    required this.count,
    required this.onTap,
  });
  final bool enabled;
  final bool loading;
  final int count;
  final VoidCallback? onTap;

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: widget.enabled
                ? (_hovered ? AppColors.ctTealDark : AppColors.ctTeal)
                : AppColors.ctTeal.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.ctNavy,
                  ),
                )
              : Text(
                  widget.count > 0
                      ? 'Enviar broadcast a ${widget.count} operadores'
                      : 'Enviar broadcast',
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

class _ConfirmBox extends StatelessWidget {
  const _ConfirmBox({
    required this.count,
    required this.onConfirm,
    required this.onCancel,
    required this.sending,
  });
  final int count;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool sending;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFF92400E)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '¿Enviar a $count operador${count != 1 ? 'es' : ''}?',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _OutlineButton(label: 'Cancelar', onTap: onCancel),
              const SizedBox(width: 10),
              _PrimaryButton(
                label: 'Confirmar envío',
                onTap: sending ? null : onConfirm,
                loading: sending,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 14, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({required this.message});
  final String message;

  bool get _isError => message.startsWith('Error');

  @override
  Widget build(BuildContext context) {
    final isError = _isError;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isError ? AppColors.ctRedBg : AppColors.ctOkBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isError
                ? const Color(0xFFFECACA)
                : AppColors.ctOk),
      ),
      child: Row(
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 15,
            color: isError ? AppColors.ctRedText : AppColors.ctOkText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isError ? AppColors.ctRedText : AppColors.ctOkText,
              ),
            ),
          ),
        ],
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

    switch (status) {
      case 'sent':
        bg        = AppColors.ctOkBg;
        textColor = AppColors.ctOkText;
        label     = 'Enviado';
      case 'failed':
        bg        = AppColors.ctRedBg;
        textColor = AppColors.ctRedText;
        label     = 'Fallido';
      case 'partial':
        bg        = const Color(0xFFFEF3C7);
        textColor = const Color(0xFF92400E);
        label     = 'Parcial';
      default:
        bg        = AppColors.ctSurface2;
        textColor = AppColors.ctText2;
        label     = status;
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

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton(
      {required this.label, required this.onTap, this.loading = false});
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.ctNavy),
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
      onExit:  (_) => setState(() => _hovered = false),
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
