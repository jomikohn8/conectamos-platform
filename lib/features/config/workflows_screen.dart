import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ── Modelos mock ──────────────────────────────────────────────────────────────

class _FieldMock {
  const _FieldMock({
    required this.name,
    required this.type,
    required this.required,
  });
  final String name;
  final String type;
  final bool required;
}

class _WorkflowMock {
  const _WorkflowMock({
    required this.number,
    required this.name,
    required this.description,
    required this.chips,
    required this.fields,
  });
  final int number;
  final String name;
  final String description;
  final List<String> chips;
  final List<_FieldMock> fields;
}

const _kWorkflows = [
  _WorkflowMock(
    number: 1,
    name: 'Flujo 1 · Turno',
    description: 'Registro de inicio y cierre de turno del operador',
    chips: ['2 campos', 'Modo: Evento único', 'Sin IDs'],
    fields: [
      _FieldMock(
          name: 'Hora de llegada', type: 'Hora automática', required: true),
      _FieldMock(
          name: 'Ubicación de inicio', type: 'Texto libre', required: true),
    ],
  ),
  _WorkflowMock(
    number: 2,
    name: 'Flujo 2 · Registros',
    description: 'Captura de eventos de entrega o registro durante el turno',
    chips: [
      '4 campos',
      'Modo: IDs por conversación',
      'IDs generados en conversación'
    ],
    fields: [
      _FieldMock(name: 'ID del registro', type: 'Texto', required: true),
      _FieldMock(name: 'Cantidad', type: 'Número', required: true),
      _FieldMock(
          name: 'Resultado',
          type: 'Selección (Exitoso / Fallido)',
          required: true),
      _FieldMock(name: 'Evidencia', type: 'Foto', required: false),
    ],
  ),
  _WorkflowMock(
    number: 3,
    name: 'Flujo 3 · Incidencias',
    description: 'Reporte de incidencias durante el turno',
    chips: [
      '3 campos',
      'Modo: IDs por conversación',
      'Alerta automática a supervisores'
    ],
    fields: [
      _FieldMock(
          name: 'Tipo de incidencia',
          type: 'Selección (Mecánica / Accidente / Retraso / Otro)',
          required: true),
      _FieldMock(name: 'Descripción', type: 'Texto libre', required: true),
      _FieldMock(name: 'Foto', type: 'Foto', required: false),
    ],
  ),
];

// ── Pantalla ──────────────────────────────────────────────────────────────────

class WorkflowsScreen extends ConsumerWidget {
  const WorkflowsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _ActionBar(
          onNew: () => showDialog(
            context: context,
            builder: (_) => const _NewWorkflowDialog(),
          ),
        ),
        const Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(22),
            child: _WorkflowsBody(),
          ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.onNew});
  final VoidCallback onNew;

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
                  'Flujos de trabajo',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                SizedBox(height: 1),
                Text(
                  'Configura los flujos de reporte de tus operadores',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                ),
              ],
            ),
          ),
          _PrimaryButton(label: '+ Nuevo flujo', onTap: onNew),
        ],
      ),
    );
  }
}

// ── Cuerpo ────────────────────────────────────────────────────────────────────

class _WorkflowsBody extends StatelessWidget {
  const _WorkflowsBody();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _kWorkflows
          .map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _WorkflowCard(workflow: w),
              ))
          .toList(),
    );
  }
}

// ── Card de flujo ─────────────────────────────────────────────────────────────

class _WorkflowCard extends StatefulWidget {
  const _WorkflowCard({required this.workflow});
  final _WorkflowMock workflow;

  @override
  State<_WorkflowCard> createState() => _WorkflowCardState();
}

class _WorkflowCardState extends State<_WorkflowCard> {
  bool _expanded = false;
  bool _active = true;

  @override
  Widget build(BuildContext context) {
    final w = widget.workflow;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        border: Border.all(color: AppColors.ctBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // ── Header de la card ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Número circular
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.ctTealLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${w.number}',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctTealDark,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Nombre + descripción
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ctText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        w.description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.ctText2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Chips de metadata
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: w.chips
                            .map((c) => _MetadataChip(label: c))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Badge estado + botones
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Badge + switch
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _active
                                ? AppColors.ctOkBg
                                : AppColors.ctSurface2,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _active ? 'Activo' : 'Inactivo',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _active
                                  ? AppColors.ctOkText
                                  : AppColors.ctText2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _active,
                            onChanged: (v) => setState(() => _active = v),
                            activeThumbColor: AppColors.ctTeal,
                            activeTrackColor:
                                AppColors.ctTeal.withValues(alpha: 0.3),
                            inactiveThumbColor: AppColors.ctBorder2,
                            inactiveTrackColor: AppColors.ctSurface2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Botón editar
                    _EditButton(onTap: () {}),
                  ],
                ),
              ],
            ),
          ),

          // ── Toggle "Ver campos" ──
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.ctBorder)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: AppColors.ctText2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _expanded ? 'Ocultar campos' : 'Ver campos',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ctText2,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.ctSurface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${w.fields.length}',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ctText2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tabla de campos expandible ──
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _FieldsTable(fields: w.fields),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

// ── Tabla de campos ───────────────────────────────────────────────────────────

class _FieldsTable extends StatelessWidget {
  const _FieldsTable({required this.fields});
  final List<_FieldMock> fields;

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
      decoration: const BoxDecoration(
        color: AppColors.ctBg,
        border: Border(top: BorderSide(color: AppColors.ctBorder)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(9),
          bottomRight: Radius.circular(9),
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('CAMPO', style: _headerStyle)),
                Expanded(flex: 2, child: Text('TIPO', style: _headerStyle)),
                Expanded(
                    flex: 1,
                    child: Text('REQUERIDO', style: _headerStyle)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.ctBorder),

          // Filas
          ...fields.asMap().entries.map((entry) {
            final isLast = entry.key == fields.length - 1;
            return Column(
              children: [
                _FieldRow(field: entry.value),
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

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field});
  final _FieldMock field;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Nombre del campo
          Expanded(
            flex: 3,
            child: Text(
              field.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText,
              ),
            ),
          ),

          // Tipo — badge gris
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ctSurface2,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: AppColors.ctBorder),
                ),
                child: Text(
                  field.type,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.ctText2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Requerido
          Expanded(
            flex: 1,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  field.required
                      ? Icons.check_circle_rounded
                      : Icons.remove_circle_outline_rounded,
                  size: 13,
                  color: field.required
                      ? AppColors.ctOk
                      : AppColors.ctText3,
                ),
                const SizedBox(width: 4),
                Text(
                  field.required ? 'Sí' : 'No',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: field.required
                        ? AppColors.ctOkText
                        : AppColors.ctText3,
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

// ── Modal nuevo flujo ─────────────────────────────────────────────────────────

class _NewWorkflowDialog extends StatefulWidget {
  const _NewWorkflowDialog();

  @override
  State<_NewWorkflowDialog> createState() => _NewWorkflowDialogState();
}

class _NewWorkflowDialogState extends State<_NewWorkflowDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  int _idMode = 0; // 0 = evento único, 1 = precargados, 2 = en conversación
  bool _alertas = false;

  static const _idModes = [
    'Evento único (sin IDs)',
    'IDs precargados',
    'IDs generados en conversación',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
              const Text(
                'Nuevo flujo de trabajo',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 20),

              // Nombre del flujo
              _DialogField(
                label: 'Nombre del flujo',
                controller: _nameCtrl,
                placeholder: 'Ej: Flujo 4 · Entregas',
              ),
              const SizedBox(height: 14),

              // Descripción
              _DialogField(
                label: 'Descripción',
                controller: _descCtrl,
                placeholder: 'Describe el propósito de este flujo...',
                maxLines: 3,
              ),
              const SizedBox(height: 18),

              // Modo de IDs
              const Text(
                'Modo de IDs',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ctBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: List.generate(_idModes.length, (i) {
                    final isLast = i == _idModes.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          borderRadius: isLast
                              ? const BorderRadius.only(
                                  bottomLeft: Radius.circular(7),
                                  bottomRight: Radius.circular(7),
                                )
                              : BorderRadius.zero,
                          onTap: () => setState(() => _idMode = i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _idMode == i
                                          ? AppColors.ctTeal
                                          : AppColors.ctBorder2,
                                      width: 1.5,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: _idMode == i
                                      ? Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.ctTeal,
                                            shape: BoxShape.circle,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _idModes[i],
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    color: AppColors.ctText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isLast)
                          const Divider(
                              height: 1, color: AppColors.ctBorder),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 14),

              // Alertas automáticas
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.ctBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(7),
                  onTap: () => setState(() => _alertas = !_alertas),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _alertas,
                            onChanged: (v) =>
                                setState(() => _alertas = v ?? false),
                            activeColor: AppColors.ctTeal,
                            checkColor: AppColors.ctNavy,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: const BorderSide(
                                color: AppColors.ctBorder2),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            '¿Genera alertas automáticas?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.ctText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
                  _PrimaryButton(
                    label: 'Crear flujo',
                    onTap: () => Navigator.pop(context),
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

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.ctSurface2,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.ctBorder),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          color: AppColors.ctText2,
        ),
      ),
    );
  }
}

class _EditButton extends StatefulWidget {
  const _EditButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_EditButton> createState() => _EditButtonState();
}

class _EditButtonState extends State<_EditButton> {
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
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.ctInfo.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: _hovered
                  ? AppColors.ctInfo.withValues(alpha: 0.4)
                  : AppColors.ctBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 13,
                color: _hovered ? AppColors.ctInfo : AppColors.ctText2,
              ),
              const SizedBox(width: 5),
              Text(
                'Editar',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _hovered ? AppColors.ctInfo : AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  const _DialogField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.maxLines = 1,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final int maxLines;

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
          maxLines: maxLines,
          minLines: maxLines,
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
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
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
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
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
