import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Cabecera de pantalla Tipo C — Patrón B (DS §2.5).
///
/// Eyebrow + título grande + descripción + acciones opcionales.
/// Sin fondo declarado (hereda del shell). Sin border-bottom.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    this.actions = const [],
  });

  final String eyebrow;
  final String title;
  final String description;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: AppFonts.geist(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ctTealText,
              letterSpacing: 0.06,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppFonts.onest(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.ctNavy,
              letterSpacing: -0.03 * 28,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppFonts.geist(
              fontSize: 14,
              color: AppColors.ctText2,
              height: 1.5,
            ),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                for (int i = 0; i < actions.length; i++) ...[
                  actions[i],
                  if (i < actions.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
