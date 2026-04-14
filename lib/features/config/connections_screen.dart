import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _tenantDetailsProvider =
    FutureProvider.autoDispose.family<Map<String, dynamic>?, String>(
  (ref, tenantId) async {
    if (tenantId.isEmpty) return null;
    try {
      final res = await ApiClient.instance.get('/tenants/$tenantId');
      return Map<String, dynamic>.from(res.data as Map);
    } catch (_) {
      return null;
    }
  },
);

// ── Pantalla ──────────────────────────────────────────────────────────────────

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantId = ref.watch(activeTenantIdProvider);
    final tenantAsync = ref.watch(_tenantDetailsProvider(tenantId));

    final waConfigured = tenantAsync.maybeWhen(
      data: (d) {
        final id = d?['wa_phone_number_id']?.toString() ?? '';
        return id.isNotEmpty;
      },
      orElse: () => false,
    );

    return Column(
      children: [
        _ActionBar(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChannelCard(
                  icon: Icons.chat_rounded,
                  iconBg: const Color(0xFFDCFCE7),
                  iconColor: const Color(0xFF16A34A),
                  title: 'WhatsApp Business API',
                  subtitle: 'Meta Cloud API',
                  connected: waConfigured,
                  onConfigure: () => context.go('/connections/whatsapp'),
                ),
                const SizedBox(height: 12),
                _ChannelCard(
                  icon: Icons.send_rounded,
                  iconBg: AppColors.ctSurface2,
                  iconColor: AppColors.ctText3,
                  title: 'Telegram',
                  subtitle: 'Telegram Bot API',
                  connected: false,
                  comingSoon: true,
                  onConfigure: null,
                ),
                const SizedBox(height: 12),
                _ChannelCard(
                  icon: Icons.sms_outlined,
                  iconBg: AppColors.ctSurface2,
                  iconColor: AppColors.ctText3,
                  title: 'SMS',
                  subtitle: 'Twilio / Vonage',
                  connected: false,
                  comingSoon: true,
                  onConfigure: null,
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
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Gestiona tus canales de comunicación',
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

// ── Card de canal ─────────────────────────────────────────────────────────────

class _ChannelCard extends StatefulWidget {
  const _ChannelCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.connected,
    this.comingSoon = false,
    required this.onConfigure,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool connected;
  final bool comingSoon;
  final VoidCallback? onConfigure;

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
          color: _hovered ? AppColors.ctBg : AppColors.ctSurface,
          border: Border.all(color: AppColors.ctBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Icono canal
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

            // Título + subtítulo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ctText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.ctText2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Badge de status + botón
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (widget.comingSoon)
                  _Badge(
                    label: 'Próximamente',
                    bg: AppColors.ctSurface2,
                    textColor: AppColors.ctText2,
                  )
                else if (widget.connected)
                  _Badge(
                    label: 'Conectado',
                    bg: const Color(0xFFDCFCE7),
                    textColor: const Color(0xFF16A34A),
                  )
                else
                  _Badge(
                    label: 'Sin configurar',
                    bg: AppColors.ctSurface2,
                    textColor: AppColors.ctText2,
                  ),
                if (widget.onConfigure != null) ...[
                  const SizedBox(height: 10),
                  _ConfigureButton(onTap: widget.onConfigure!),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets locales ───────────────────────────────────────────────────────────

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

class _ConfigureButton extends StatefulWidget {
  const _ConfigureButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_ConfigureButton> createState() => _ConfigureButtonState();
}

class _ConfigureButtonState extends State<_ConfigureButton> {
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.ctTealDark : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Text(
            'Configurar',
            style: TextStyle(
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
