import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class AiWorker {
  const AiWorker({
    required this.id,
    required this.name,
    required this.workerType,
    required this.color,
    required this.webhookUrl,
    required this.status,
    this.description,
  });
  final String id;
  final String name;
  final String workerType; // 'logistics' | 'sales' | 'support' | 'custom'
  final String color;      // hex
  final String webhookUrl;
  final String status;     // 'active' | 'inactive'
  final String? description;

  AiWorker copyWith({
    String? name,
    String? workerType,
    String? color,
    String? webhookUrl,
    String? status,
    Object? description = _sentinel,
  }) {
    return AiWorker(
      id: id,
      name: name ?? this.name,
      workerType: workerType ?? this.workerType,
      color: color ?? this.color,
      webhookUrl: webhookUrl ?? this.webhookUrl,
      status: status ?? this.status,
      description: description == _sentinel
          ? this.description
          : description as String?,
    );
  }
}

const _sentinel = Object();

// ── Constants ─────────────────────────────────────────────────────────────────

const _kColorPalette = [
  '#2DD4BF', '#818CF8', '#FB923C', '#F472B6', '#34D399', '#60A5FA',
];

const _kInitialWorkers = [
  AiWorker(
    id: 'w1',
    name: 'Worker Logística',
    workerType: 'logistics',
    color: '#2DD4BF',
    webhookUrl: 'https://api.conectamos.ai/workers/logistics',
    status: 'active',
    description: 'Gestiona reportes de entrega y seguimiento de rutas',
  ),
  AiWorker(
    id: 'w2',
    name: 'Worker Ventas',
    workerType: 'sales',
    color: '#818CF8',
    webhookUrl: 'https://api.conectamos.ai/workers/sales',
    status: 'active',
    description: 'Captura pedidos, precios y seguimiento de clientes',
  ),
  AiWorker(
    id: 'w3',
    name: 'Worker Soporte',
    workerType: 'support',
    color: '#FB923C',
    webhookUrl: 'https://api.conectamos.ai/workers/support',
    status: 'inactive',
    description: 'Atención a operadores con dudas o incidencias',
  ),
];

const _kTypeConfig = {
  'logistics': (label: 'Logística', bg: Color(0xFFDBEAFE), fg: Color(0xFF1E40AF)),
  'sales':     (label: 'Ventas',    bg: Color(0xFFEDE9FE), fg: Color(0xFF6D28D9)),
  'support':   (label: 'Soporte',   bg: Color(0xFFFFEDD5), fg: Color(0xFFC2410C)),
  'custom':    (label: 'Custom',    bg: Color(0xFFF3F4F6), fg: Color(0xFF374151)),
};

const _kTypeOptions = ['logistics', 'sales', 'support', 'custom'];

// ── Helper ────────────────────────────────────────────────────────────────────

Color _hexColor(String hex) {
  final h = hex.replaceAll('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AiWorkersScreen extends ConsumerStatefulWidget {
  const AiWorkersScreen({super.key});

  @override
  ConsumerState<AiWorkersScreen> createState() => _AiWorkersScreenState();
}

class _AiWorkersScreenState extends ConsumerState<AiWorkersScreen> {
  late List<AiWorker> _workers;

  @override
  void initState() {
    super.initState();
    _workers = List.of(_kInitialWorkers);
  }

  void _upsertWorker(AiWorker w) {
    setState(() {
      final idx = _workers.indexWhere((e) => e.id == w.id);
      if (idx >= 0) {
        _workers[idx] = w;
      } else {
        _workers = [..._workers, w];
      }
    });
  }

  void _toggleStatus(String id) {
    setState(() {
      _workers = _workers.map((w) {
        if (w.id != id) return w;
        return w.copyWith(
          status: w.status == 'active' ? 'inactive' : 'active',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBar(
          onAdd: () async {
            await showDialog(
              context: context,
              builder: (_) => _WorkerFormDialog(onSaved: _upsertWorker),
            );
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: _WorkersBody(
              workers: _workers,
              onToggle: _toggleStatus,
              onEdit: (worker) async {
                await showDialog(
                  context: context,
                  builder: (_) => _WorkerFormDialog(
                    worker: worker,
                    onSaved: _upsertWorker,
                  ),
                );
              },
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
                  'AI Workers',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Configura los workers de inteligencia artificial por canal',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryBtn(label: '+ Nuevo worker', onTap: onAdd),
        ],
      ),
    );
  }
}

// ── Workers body ──────────────────────────────────────────────────────────────

class _WorkersBody extends StatelessWidget {
  const _WorkersBody({
    required this.workers,
    required this.onToggle,
    required this.onEdit,
  });
  final List<AiWorker> workers;
  final void Function(String id) onToggle;
  final void Function(AiWorker w) onEdit;

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
                Expanded(flex: 3, child: Text('WORKER',      style: _headerStyle)),
                Expanded(flex: 2, child: Text('TIPO',        style: _headerStyle)),
                Expanded(flex: 3, child: Text('WEBHOOK URL', style: _headerStyle)),
                Expanded(flex: 1, child: Text('ESTADO',      style: _headerStyle)),
                Expanded(flex: 2, child: Text('ACCIONES',    style: _headerStyle)),
              ],
            ),
          ),

          // Rows
          if (workers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'No hay AI Workers configurados.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.ctText2,
                  ),
                ),
              ),
            )
          else
            ...workers.asMap().entries.map((entry) {
              final isLast = entry.key == workers.length - 1;
              return Column(
                children: [
                  _WorkerRow(
                    worker: entry.value,
                    onToggle: () => onToggle(entry.value.id),
                    onEdit: () => onEdit(entry.value),
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

// ── Worker row ────────────────────────────────────────────────────────────────

class _WorkerRow extends StatefulWidget {
  const _WorkerRow({
    required this.worker,
    required this.onToggle,
    required this.onEdit,
  });
  final AiWorker worker;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  @override
  State<_WorkerRow> createState() => _WorkerRowState();
}

class _WorkerRowState extends State<_WorkerRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    final isActive = w.status == 'active';
    final typeEntry = _kTypeConfig[w.workerType] ??
        _kTypeConfig['custom']!;
    final color = _hexColor(w.color);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Worker: dot + name + description
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
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
                          w.name,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ctText,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (w.description != null &&
                            w.description!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            w.description!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.ctText2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tipo
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _TypeBadge(
                  label: typeEntry.label,
                  bg: typeEntry.bg,
                  fg: typeEntry.fg,
                ),
              ),
            ),

            // Webhook URL
            Expanded(
              flex: 3,
              child: Text(
                w.webhookUrl,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Estado
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

            // Acciones
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
                  const SizedBox(width: 6),
                  _ActionBtn(
                    label: isActive ? 'Desactivar' : 'Activar',
                    color: isActive
                        ? AppColors.ctDanger
                        : AppColors.ctOk,
                    onTap: widget.onToggle,
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

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.bg,
    required this.fg,
  });
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
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
          color: fg,
        ),
      ),
    );
  }
}

// ── Worker form dialog ────────────────────────────────────────────────────────

class _WorkerFormDialog extends StatefulWidget {
  const _WorkerFormDialog({
    this.worker,
    required this.onSaved,
  });
  final AiWorker? worker;
  final void Function(AiWorker) onSaved;

  bool get isEdit => worker != null;

  @override
  State<_WorkerFormDialog> createState() => _WorkerFormDialogState();
}

class _WorkerFormDialogState extends State<_WorkerFormDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _webhookCtrl;
  late final TextEditingController _descCtrl;
  late String _workerType;
  late String _color;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    final w = widget.worker;
    _nameCtrl    = TextEditingController(text: w?.name ?? '');
    _webhookCtrl = TextEditingController(text: w?.webhookUrl ?? '');
    _descCtrl    = TextEditingController(text: w?.description ?? '');
    _workerType  = w?.workerType ?? 'logistics';
    _color       = w?.color ?? _kColorPalette.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _webhookCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name    = _nameCtrl.text.trim();
    final webhook = _webhookCtrl.text.trim();
    if (name.isEmpty || webhook.isEmpty) {
      setState(() => _errorMsg = 'Nombre y Webhook URL son obligatorios.');
      return;
    }
    final saved = AiWorker(
      id: widget.worker?.id ??
          'w_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      workerType: _workerType,
      color: _color,
      webhookUrl: webhook,
      status: widget.worker?.status ?? 'active',
      description: _descCtrl.text.trim().isEmpty
          ? null
          : _descCtrl.text.trim(),
    );
    Navigator.pop(context);
    widget.onSaved(saved);
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
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                widget.isEdit ? 'Editar AI Worker' : 'Nuevo AI Worker',
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
                label: 'Nombre del worker',
                controller: _nameCtrl,
                placeholder: 'Ej: Worker Logística',
              ),
              const SizedBox(height: 14),

              // Tipo
              const Text(
                'Tipo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
                    value: _workerType,
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
                    items: _kTypeOptions.map((t) {
                      final cfg = _kTypeConfig[t] ?? _kTypeConfig['custom']!;
                      return DropdownMenuItem(
                        value: t,
                        child: Text(cfg.label),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _workerType = v);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Color
              const Text(
                'Color',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: _kColorPalette.map((hex) {
                  final selected = _color == hex;
                  final color = _hexColor(hex);
                  return GestureDetector(
                    onTap: () => setState(() => _color = hex),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: selected
                              ? Border.all(
                                  color: AppColors.ctNavy,
                                  width: 2,
                                )
                              : null,
                          boxShadow: selected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Webhook URL
              _DialogField(
                label: 'Webhook URL',
                controller: _webhookCtrl,
                placeholder: 'https://',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),

              // Descripción
              const Text(
                'Descripción (opcional)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                minLines: 3,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
                decoration: InputDecoration(
                  hintText: 'Describe qué hace este worker…',
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
                  _GhostBtn(
                    label: 'Cancelar',
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  _PrimaryBtn(
                    label: 'Guardar',
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

// ── Button helpers ────────────────────────────────────────────────────────────

class _PrimaryBtn extends StatefulWidget {
  const _PrimaryBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

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
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
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
