import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';

// ── Pantalla ──────────────────────────────────────────────────────────────────

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Section 1: Canales ──────────────────────────────────────
                const Text(
                  'Canales de comunicación',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Gestiona los canales por los que recibes y envías mensajes.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                ),
                const SizedBox(height: 16),
                _ChannelCard(
                  icon: Icons.chat_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF25D366),
                  title: 'WhatsApp Business API',
                  subtitle: 'Meta Cloud API',
                  actionLabel: 'Gestionar canales',
                  onAction: () => context.go('/channels'),
                ),
                const SizedBox(height: 12),
                _ChannelCard(
                  icon: Icons.send_rounded,
                  iconBg: const Color(0xFFE0F2FE),
                  iconColor: const Color(0xFF229ED9),
                  title: 'Telegram',
                  subtitle: 'Telegram Bot API',
                  comingSoon: true,
                ),
                const SizedBox(height: 12),
                _ChannelCard(
                  icon: Icons.sms_outlined,
                  iconBg: AppColors.ctSurface2,
                  iconColor: const Color(0xFF6B7280),
                  title: 'SMS',
                  subtitle: 'Twilio / Vonage',
                  comingSoon: true,
                ),
                const SizedBox(height: 12),
                _ChannelCard(
                  icon: Icons.facebook_rounded,
                  iconBg: const Color(0xFFDBEAFE),
                  iconColor: const Color(0xFF1877F2),
                  title: 'Facebook Messenger',
                  subtitle: 'Meta Graph API',
                  comingSoon: true,
                ),

                const SizedBox(height: 32),

                // ── Section 2: Integraciones ────────────────────────────────
                const Text(
                  'Integraciones de datos',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctText,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Conecta tu CRM, ERP u otras fuentes de datos.',
                  style: TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    color: AppColors.ctText2,
                  ),
                ),
                const SizedBox(height: 16),
                _DashedCard(
                  icon: Icons.extension_outlined,
                  label: 'Más integraciones próximamente',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Action bar ────────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
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
                'Conexiones',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Canales de comunicación e integraciones',
                style: TextStyle(
                  fontFamily: 'Geist',
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

// ── Channel Card ──────────────────────────────────────────────────────────────

class _ChannelCard extends StatefulWidget {
  const _ChannelCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.comingSoon = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool comingSoon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<_ChannelCard> createState() => _ChannelCardState();
}

class _ChannelCardState extends State<_ChannelCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _hovered && !widget.comingSoon
              ? AppColors.ctBg
              : AppColors.ctSurface,
          border: Border.all(color: AppColors.ctBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(widget.icon, size: 22, color: widget.iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            if (widget.comingSoon)
              _Badge(
                label: 'Próximamente',
                bg: AppColors.ctSurface2,
                textColor: AppColors.ctText2,
              )
            else if (widget.onAction != null)
              _ActionButton(
                label: widget.actionLabel ?? 'Configurar',
                onTap: widget.onAction!,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Dashed placeholder card ───────────────────────────────────────────────────

class _DashedCard extends StatelessWidget {
  const _DashedCard({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.ctBorder2,
          width: 1.5,
          // Dashed effect via custom painter not available natively;
          // using solid thin border as closest approximation.
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: AppColors.ctBorder2),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctText3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.textColor});
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
          fontFamily: 'Geist',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({required this.label, required this.onTap});
  final String label;
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
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontFamily: 'Geist',
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
