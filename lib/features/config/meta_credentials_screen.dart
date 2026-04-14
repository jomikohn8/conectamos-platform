import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';

// ── Pantalla ──────────────────────────────────────────────────────────────────

class MetaCredentialsScreen extends ConsumerWidget {
  const MetaCredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Column(
      children: [
        _ActionBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(22),
            child: _MetaCredentialsBody(),
          ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  const _ActionBar();

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
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Credenciales Meta',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Conecta tu cuenta de Meta Business para usar WhatsApp API',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.ctText2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Cuerpo ────────────────────────────────────────────────────────────────────

class _MetaCredentialsBody extends StatelessWidget {
  const _MetaCredentialsBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatusCard(),
        SizedBox(height: 16),
        _PhoneNumbersTable(),
        SizedBox(height: 16),
        _TokenCard(),
      ],
    );
  }
}

// ── Sección 1: Estado de conexión ─────────────────────────────────────────────

class _StatusCard extends StatelessWidget {
  const _StatusCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Cuenta de Meta Business',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              const SizedBox(width: 10),
              _Badge(
                label: 'Conectado',
                bg: AppColors.ctOkBg,
                textColor: AppColors.ctOkText,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fila de estado activo
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ctOkBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.ctOk.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: AppColors.ctOk,
                ),
                SizedBox(width: 8),
                Text(
                  'Tu cuenta de Meta Business está activa y verificada',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.ctOkText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Grid de datos 2 columnas
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 500;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      child: Column(
                        children: [
                          _DataField(
                            label: 'Business ID',
                            value: '1234567890',
                          ),
                          SizedBox(height: 12),
                          _DataField(
                            label: 'Estado de verificación',
                            valueWidget: _Badge(
                              label: 'Verificado',
                              bg: AppColors.ctOkBg,
                              textColor: AppColors.ctOkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _DataField(
                            label: 'Nombre de cuenta',
                            value: 'Demo Business Account',
                          ),
                          SizedBox(height: 12),
                          _DataField(
                            label: 'Fecha de conexión',
                            value: '01 Ene 2026',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DataField(label: 'Business ID', value: '1234567890'),
                  SizedBox(height: 12),
                  _DataField(
                    label: 'Nombre de cuenta',
                    value: 'Demo Business Account',
                  ),
                  SizedBox(height: 12),
                  _DataField(
                    label: 'Estado de verificación',
                    valueWidget: _Badge(
                      label: 'Verificado',
                      bg: AppColors.ctOkBg,
                      textColor: AppColors.ctOkText,
                    ),
                  ),
                  SizedBox(height: 12),
                  _DataField(label: 'Fecha de conexión', value: '01 Ene 2026'),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Botón desconectar
          const Align(
            alignment: Alignment.centerRight,
            child: _DangerGhostButton(
              label: 'Desconectar cuenta',
              icon: Icons.link_off_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección 2: Números de WhatsApp ────────────────────────────────────────────

class _PhoneNumbersTable extends StatelessWidget {
  const _PhoneNumbersTable();

  static const _headerStyle = TextStyle(
    fontFamily: 'Inter',
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.ctText2,
    letterSpacing: 0.4,
  );

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Números de WhatsApp',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
              ),
              _PrimaryButton(
                label: '+ Agregar número',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tabla Column+Row
          Container(
            decoration: BoxDecoration(
              color: AppColors.ctSurface,
              border: Border.all(color: AppColors.ctBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(7),
                      topRight: Radius.circular(7),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Expanded(flex: 2, child: Text('NÚMERO', style: _headerStyle)),
                      Expanded(flex: 3, child: Text('NOMBRE DEL PERFIL', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('ESTADO', style: _headerStyle)),
                      Expanded(flex: 1, child: Text('CALIDAD', style: _headerStyle)),
                      Expanded(flex: 2, child: Text('ACCIONES', style: _headerStyle)),
                    ],
                  ),
                ),

                // Fila 1
                _PhoneRow(
                  number: '+52 55 1234 5678',
                  profile: 'ConectamOS Operaciones',
                  statusLabel: 'Activo',
                  statusBg: AppColors.ctOkBg,
                  statusColor: AppColors.ctOkText,
                  qualityLabel: 'Alta',
                  qualityBg: AppColors.ctOkBg,
                  qualityColor: AppColors.ctOkText,
                ),
                const Divider(height: 1, color: AppColors.ctBorder),

                // Fila 2
                _PhoneRow(
                  number: '+52 55 9876 5432',
                  profile: 'ConectamOS Soporte',
                  statusLabel: 'Pendiente',
                  statusBg: AppColors.ctWarnBg,
                  statusColor: AppColors.ctWarnText,
                  qualityLabel: '—',
                  qualityBg: AppColors.ctSurface2,
                  qualityColor: AppColors.ctText2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatefulWidget {
  const _PhoneRow({
    required this.number,
    required this.profile,
    required this.statusLabel,
    required this.statusBg,
    required this.statusColor,
    required this.qualityLabel,
    required this.qualityBg,
    required this.qualityColor,
  });
  final String number;
  final String profile;
  final String statusLabel;
  final Color statusBg;
  final Color statusColor;
  final String qualityLabel;
  final Color qualityBg;
  final Color qualityColor;

  @override
  State<_PhoneRow> createState() => _PhoneRowState();
}

class _PhoneRowState extends State<_PhoneRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Número
            Expanded(
              flex: 2,
              child: Text(
                widget.number,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText,
                ),
              ),
            ),
            // Nombre del perfil
            Expanded(
              flex: 3,
              child: Text(
                widget.profile,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.ctText,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Estado
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(
                  label: widget.statusLabel,
                  bg: widget.statusBg,
                  textColor: widget.statusColor,
                ),
              ),
            ),
            // Calidad
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _Badge(
                  label: widget.qualityLabel,
                  bg: widget.qualityBg,
                  textColor: widget.qualityColor,
                ),
              ),
            ),
            // Acciones
            Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TableGhostButton(label: 'Ver detalles', onTap: () {}),
                  const SizedBox(width: 6),
                  _TableGhostButton(label: 'Configurar', onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sección 3: Token de acceso ────────────────────────────────────────────────

class _TokenCard extends StatefulWidget {
  const _TokenCard();

  @override
  State<_TokenCard> createState() => _TokenCardState();
}

class _TokenCardState extends State<_TokenCard> {
  static const _fullToken =
      'EAABsbCS0zC4BOZBkE8pLqZA1UxiZBZCmZAEDlW9mT2cQkOhvFEqaGmWx7nZB4yVr2xKpM5';
  static const _maskedToken = 'EAABsbCS0... ••••••••••••••••••••••••••••••••••';

  Future<void> _copyToken(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _fullToken));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_rounded, size: 15, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Token copiado',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.ctNavy,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Token de acceso',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
              ),
              _Badge(
                label: 'Expira en 45 días',
                bg: AppColors.ctWarnBg,
                textColor: AppColors.ctWarnText,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Label
          const Text(
            'Token activo',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText2,
            ),
          ),
          const SizedBox(height: 6),

          // Campo token + botón copiar
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.ctSurface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.ctBorder2),
                  ),
                  child: const Text(
                    _maskedToken,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppColors.ctText2,
                      letterSpacing: 0.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _CopyButton(onTap: () => _copyToken(context)),
            ],
          ),
          const SizedBox(height: 12),

          // Botón regenerar
          const Align(
            alignment: Alignment.centerLeft,
            child: _GhostButton(
              label: 'Regenerar token',
              icon: Icons.refresh_rounded,
            ),
          ),
          const SizedBox(height: 14),

          // Texto informativo
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.ctSurface2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: AppColors.ctText3,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'El token se usa para autenticar las llamadas a la API de WhatsApp Business. Mantenlo seguro.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.ctText2,
                      height: 1.5,
                    ),
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

// ── Widgets reutilizables ─────────────────────────────────────────────────────

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

class _Badge extends StatelessWidget {
  const _Badge({
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

class _DataField extends StatelessWidget {
  const _DataField({
    required this.label,
    this.value,
    this.valueWidget,
  }) : assert(value != null || valueWidget != null);
  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.ctText2,
          ),
        ),
        const SizedBox(height: 4),
        valueWidget ??
            Text(
              value!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.ctText,
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
  const _GhostButton({required this.label, this.icon});
  final String label;
  final IconData? icon;

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
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.ctBorder2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 13, color: AppColors.ctText2),
                const SizedBox(width: 5),
              ],
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DangerGhostButton extends StatefulWidget {
  const _DangerGhostButton({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  State<_DangerGhostButton> createState() => _DangerGhostButtonState();
}

class _DangerGhostButtonState extends State<_DangerGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctRedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? AppColors.ctDanger.withValues(alpha: 0.4)
                  : AppColors.ctBorder2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 13,
                color: _hovered
                    ? AppColors.ctDanger
                    : AppColors.ctText2,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _hovered
                      ? AppColors.ctDanger
                      : AppColors.ctText2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TableGhostButton extends StatefulWidget {
  const _TableGhostButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_TableGhostButton> createState() => _TableGhostButtonState();
}

class _TableGhostButtonState extends State<_TableGhostButton> {
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
            color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _hovered
                  ? AppColors.ctBorder2
                  : AppColors.ctBorder,
            ),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: 'Copiar token',
        waitDuration: const Duration(milliseconds: 400),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.ctSurface2 : AppColors.ctSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.ctBorder2),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.copy_rounded,
              size: 15,
              color: AppColors.ctText2,
            ),
          ),
        ),
      ),
    );
  }
}
