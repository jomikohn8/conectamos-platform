import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/flows_api.dart';
import '../../core/api/operators_api.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Helpers ────────────────────────────────────────────────────────────────────

String _initials(String name) {
  final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
}

String _formatLastEvent(String? iso) {
  if (iso == null) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return 'Hace ${diff.inDays} días';
  } catch (_) {
    return '—';
  }
}

({String label, Color bg, Color fg}) _statusStyle(String? status) {
  switch (status) {
    case 'active':
      return (
        label: 'Activo',
        bg: AppColors.ctOkBg,
        fg: AppColors.ctOkText
      );
    case 'incident':
      return (
        label: 'Incidencia',
        bg: AppColors.ctRedBg,
        fg: AppColors.ctRedText
      );
    case 'suspended':
      return (
        label: 'Suspendido',
        bg: AppColors.ctSurface2,
        fg: AppColors.ctText2
      );
    default:
      return (
        label: 'Sin inicio',
        bg: AppColors.ctSurface2,
        fg: AppColors.ctText2
      );
  }
}

// ── Pantalla ──────────────────────────────────────────────────────────────────

class OperatorsScreen extends ConsumerStatefulWidget {
  const OperatorsScreen({super.key});

  @override
  ConsumerState<OperatorsScreen> createState() => _OperatorsScreenState();
}

class _OperatorsScreenState extends ConsumerState<OperatorsScreen> {
  List<Map<String, dynamic>> _operators = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOperators();
  }

  Future<void> _fetchOperators() async {
    setState(() => _loading = true);
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final ops = await OperatorsApi.listOperators(
        tenantId: tenantId.isNotEmpty ? tenantId : 'default',
      );
      if (mounted) {
        setState(() {
          _operators = ops;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recarga operadores cuando cambia el tenant
    ref.listen<String>(activeTenantIdProvider, (prev, next) {
      if (prev != null && prev != next) _fetchOperators();
    });

    return Column(
      children: [
        _ActionBar(
          onAdd: () async {
            await showDialog(
              context: context,
              builder: (_) =>
                  _OperatorFormDialog(onSaved: _fetchOperators),
            );
          },
        ),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: _OperatorsBody(
                    operators: _operators,
                    onRefresh: _fetchOperators,
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onAdd});
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
                  'Operadores',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Gestiona los operadores y sus permisos de acceso',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryButton(label: '+ Agregar operador', onTap: onAdd),
        ],
      ),
    );
  }
}

// ── Cuerpo ────────────────────────────────────────────────────────────────────

class _OperatorsBody extends StatefulWidget {
  const _OperatorsBody({
    required this.operators,
    required this.onRefresh,
  });
  final List<Map<String, dynamic>> operators;
  final VoidCallback onRefresh;

  @override
  State<_OperatorsBody> createState() => _OperatorsBodyState();
}

class _OperatorsBodyState extends State<_OperatorsBody> {
  String _search = '';
  String _filterStatus = 'Todos';
  String _filterFlow = 'Todos';

  static const _statusOptions = [
    'Todos',
    'Activo',
    'Incidencia',
    'Sin inicio',
    'Suspendido',
  ];

  static const _flowOptions = [
    'Todos',
    'Flujo 1 · Turno',
    'Flujo 2 · Registros',
    'Flujo 3 · Incidencias',
  ];

  List<Map<String, dynamic>> get _filtered {
    return widget.operators.where((op) {
      final name = op['display_name'] as String? ??
          op['name'] as String? ?? '';
      final phone = op['phone'] as String? ?? '';
      final q = _search.toLowerCase();
      final matchSearch = q.isEmpty ||
          name.toLowerCase().contains(q) ||
          phone.contains(q);

      final status = op['status'] as String?;
      final st = _statusStyle(status);
      final matchStatus =
          _filterStatus == 'Todos' || st.label == _filterStatus;

      final flows =
          List<String>.from(op['flows'] as List? ?? []);
      final matchFlow = _filterFlow == 'Todos' ||
          flows.any((f) => _filterFlow.startsWith(f));

      return matchSearch && matchStatus && matchFlow;
    }).toList();
  }

  static const _headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.ctText2,
    letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    final rows = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filtros
        Row(
          children: [
            Expanded(
              child: _SearchField(
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(width: 10),
            _FilterDropdown(
              width: 180,
              value: _filterStatus,
              options: _statusOptions,
              onChanged: (v) => setState(() => _filterStatus = v),
            ),
            const SizedBox(width: 10),
            _FilterDropdown(
              width: 200,
              value: _filterFlow,
              options: _flowOptions,
              onChanged: (v) => setState(() => _filterFlow = v),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Tabla
        Container(
          decoration: BoxDecoration(
            color: AppColors.ctSurface,
            border: Border.all(color: AppColors.ctBorder),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: const BoxDecoration(
                  color: AppColors.ctSurface2,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                ),
                child: const Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child:
                            Text('OPERADOR', style: _headerStyle)),
                    Expanded(
                        flex: 2,
                        child:
                            Text('TELÉFONO', style: _headerStyle)),
                    Expanded(
                        flex: 1,
                        child: Text('ESTADO', style: _headerStyle)),
                    Expanded(
                        flex: 3,
                        child: Text('FLUJOS ASIGNADOS',
                            style: _headerStyle)),
                    Expanded(
                        flex: 2,
                        child: Text('ÚLTIMO ACCESO',
                            style: _headerStyle)),
                    Expanded(
                        flex: 2,
                        child:
                            Text('ACCIONES', style: _headerStyle)),
                  ],
                ),
              ),

              // Filas
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'Sin resultados para los filtros aplicados.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ),
                )
              else
                ...rows.asMap().entries.map((entry) {
                  final isLast = entry.key == rows.length - 1;
                  return Column(
                    children: [
                      _OperatorRow(
                        op: entry.value,
                        onRefresh: widget.onRefresh,
                      ),
                      if (!isLast)
                        const Divider(
                            height: 1, color: AppColors.ctBorder),
                    ],
                  );
                }),
            ],
          ),
        ),

        // Pie de tabla
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '${rows.length} de ${widget.operators.length} operadores',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Fila de operador ──────────────────────────────────────────────────────────

class _OperatorRow extends StatefulWidget {
  const _OperatorRow({required this.op, required this.onRefresh});
  final Map<String, dynamic> op;
  final VoidCallback onRefresh;

  @override
  State<_OperatorRow> createState() => _OperatorRowState();
}

class _OperatorRowState extends State<_OperatorRow> {
  bool _hovered = false;

  Future<void> _patchStatus(BuildContext ctx, String status) async {
    final id = widget.op['id'] as String? ?? '';
    if (id.isEmpty) return;
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await OperatorsApi.patchStatus(id: id, status: status);
      widget.onRefresh();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Error al cambiar el estado'),
            backgroundColor: AppColors.ctDanger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final op = widget.op;
    final name = op['display_name'] as String? ??
        op['name'] as String? ?? '—';
    final phone = op['phone'] as String? ?? '—';
    final status = op['status'] as String?;
    final verified = op['whatsapp_verified'] as bool? ?? false;
    final flows =
        List<String>.from(op['flows'] as List? ?? []);
    final lastEventAt = op['last_event_at'] as String?;
    final id = op['id'] as String? ?? '';
    final st = _statusStyle(status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Operador: avatar + nombre + verificación
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.ctTealLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(name),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ctTealDark,
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
                        const SizedBox(height: 2),
                        if (verified)
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 11,
                                color: AppColors.ctOk,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'WhatsApp verificado',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: AppColors.ctText2,
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFEDD5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Pendiente verificación',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF9A3412),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Teléfono
            Expanded(
              flex: 2,
              child: Text(
                phone,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
              ),
            ),

            // Estado
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusBadge(
                  label: st.label,
                  bg: st.bg,
                  textColor: st.fg,
                ),
              ),
            ),

            // Flujos asignados
            Expanded(
              flex: 3,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: flows
                    .map((f) => _FlowBadge(label: f))
                    .toList(),
              ),
            ),

            // Último acceso
            Expanded(
              flex: 2,
              child: Text(
                _formatLastEvent(lastEventAt),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    label: 'Editar',
                    color: AppColors.ctInfo,
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => _OperatorFormDialog(
                          operatorId: id,
                          initialName: name,
                          initialPhone: phone,
                          initialFlows: flows,
                          onSaved: widget.onRefresh,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  if (status == 'active' || status == 'incident')
                    _ActionButton(
                      label: 'Suspender',
                      color: AppColors.ctDanger,
                      onTap: () => _patchStatus(context, 'suspended'),
                    )
                  else
                    _ActionButton(
                      label: 'Reactivar',
                      color: AppColors.ctOk,
                      onTap: () => _patchStatus(context, 'active'),
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

// ── Modal crear / editar operador ─────────────────────────────────────────────

class _OperatorFormDialog extends ConsumerStatefulWidget {
  const _OperatorFormDialog({
    this.operatorId,
    this.initialName,
    this.initialPhone,
    this.initialFlows,
    required this.onSaved,
  });

  final String? operatorId;
  final String? initialName;
  final String? initialPhone;
  final List<String>? initialFlows;
  final VoidCallback onSaved;

  bool get isEdit => operatorId != null;

  @override
  ConsumerState<_OperatorFormDialog> createState() => _OperatorFormDialogState();
}

class _OperatorFormDialogState extends ConsumerState<_OperatorFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;
  String? _errorMsg;

  // Flows loaded from API
  List<Map<String, dynamic>> _availableFlows = [];
  bool _flowsLoading = true;
  // IDs of currently selected flows
  Set<String> _selectedFlowIds = {};

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialPhone ?? '');
    _selectedFlowIds = Set<String>.from(widget.initialFlows ?? []);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFlows());
  }

  Future<void> _loadFlows() async {
    try {
      final tenantId = ref.read(activeTenantIdProvider);
      final flows = await FlowsApi.listFlows(
        tenantId: tenantId.isNotEmpty ? tenantId : 'default',
      );
      if (mounted) setState(() { _availableFlows = flows; _flowsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _flowsLoading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _errorMsg = 'Nombre y teléfono son obligatorios.');
      return;
    }
    setState(() { _saving = true; _errorMsg = null; });

    try {
      final flows = _selectedFlowIds.toList();
      if (widget.isEdit) {
        await OperatorsApi.updateOperator(
          id: widget.operatorId!,
          displayName: name,
          phone: phone,
          flows: flows,
        );
      } else {
        final tenantId = ref.read(activeTenantIdProvider);
        await OperatorsApi.createOperator(
          displayName: name,
          phone: phone,
          flows: flows,
          tenantId: tenantId.isNotEmpty ? tenantId : 'default',
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEdit ? 'Operador actualizado.' : 'Operador creado. Mensaje de bienvenida enviado.',
              style: const TextStyle(fontFamily: 'Inter', fontSize: 13),
            ),
            backgroundColor: AppColors.ctNavy,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      setState(() {
        _saving = false;
        _errorMsg = code == 409
            ? 'Ya existe un operador con ese número de teléfono.'
            : 'Error al guardar. Intenta de nuevo.';
      });
    } catch (_) {
      setState(() { _saving = false; _errorMsg = 'Error inesperado. Intenta de nuevo.'; });
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
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.isEdit ? 'Editar operador' : 'Agregar operador',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre
              _DialogField(
                label: 'Nombre completo',
                controller: _nameCtrl,
                placeholder: 'Ej: Roberto Medina',
              ),
              const SizedBox(height: 14),

              // Teléfono
              _DialogField(
                label: 'Número de WhatsApp',
                controller: _phoneCtrl,
                placeholder: '521XXXXXXXXXX',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 18),

              // Flujos
              const Text(
                'Flujos asignados',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ctText),
              ),
              const SizedBox(height: 6),
              if (_flowsLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctTeal))),
                )
              else if (_availableFlows.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.ctBorder), borderRadius: BorderRadius.circular(8)),
                  child: const Text('No hay flujos disponibles en este tenant.', style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.ctText2)),
                )
              else
                Container(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.ctBorder), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: _availableFlows.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final flow = entry.value;
                      final flowId = flow['id'] as String? ?? '';
                      final flowName = flow['name'] as String? ?? flowId;
                      final workerName = flow['worker_name'] as String? ?? flow['tenant_worker_name'] as String? ?? '';
                      final isFlowActive = flow['is_active'] as bool? ?? true;
                      final isSelected = _selectedFlowIds.contains(flowId);
                      final isLast = idx == _availableFlows.length - 1;
                      return Column(
                        children: [
                          InkWell(
                            borderRadius: isLast
                                ? const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))
                                : BorderRadius.zero,
                            onTap: () => setState(() {
                              if (isSelected) { _selectedFlowIds.remove(flowId); }
                              else { _selectedFlowIds.add(flowId); }
                            }),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 20, height: 20,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (v) => setState(() {
                                        if (v == true) { _selectedFlowIds.add(flowId); }
                                        else { _selectedFlowIds.remove(flowId); }
                                      }),
                                      activeColor: AppColors.ctTeal,
                                      checkColor: AppColors.ctNavy,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      side: const BorderSide(color: AppColors.ctBorder2),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(flowName, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.ctText)),
                                        if (workerName.isNotEmpty)
                                          Text(workerName, style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.ctText2)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isFlowActive ? AppColors.ctOkBg : AppColors.ctSurface2,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isFlowActive ? 'Activo' : 'Inactivo',
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600, color: isFlowActive ? AppColors.ctOkText : AppColors.ctText2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (!isLast) const Divider(height: 1, color: AppColors.ctBorder),
                        ],
                      );
                    }).toList(),
                  ),
                ),

              // Error
              if (_errorMsg != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.ctRedBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctRedText,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _GhostButton(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  if (_saving)
                    const SizedBox(
                      width: 120,
                      height: 36,
                      child: Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      ),
                    )
                  else
                    _PrimaryButton(
                      label: 'Guardar operador',
                      onTap: _save,
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

// ── _DialogField ──────────────────────────────────────────────────────────────

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
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
              borderSide: const BorderSide(
                  color: AppColors.ctTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets reutilizables ─────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        color: AppColors.ctText,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar por nombre o teléfono...',
        hintStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: AppColors.ctText3,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 17,
          color: AppColors.ctText3,
        ),
        filled: true,
        fillColor: AppColors.ctSurface,
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

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.width,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final double width;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.ctSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.ctBorder2),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isDense: true,
            isExpanded: true,
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
            items: options
                .map((o) =>
                    DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.bg,
    required this.textColor,
  });
  final String label;
  final Color bg;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

class _FlowBadge extends StatelessWidget {
  const _FlowBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.ctInfoBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.ctInfoText,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
  });
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
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
          duration: const Duration(milliseconds: 100),
          padding:
              const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
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
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctTealDark
                : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
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
  const _GhostButton({required this.label, required this.onTap});
  final String label;
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
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctSurface2
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}
