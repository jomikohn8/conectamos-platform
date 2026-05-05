import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Cabecera canónica de pantalla (Pattern A — sub-bar).
///
/// Muestra [title] y [subtitle] a la izquierda; [actions] a la derecha
/// separados por 8px entre sí.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppFonts.onest(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ctText,
                ),
              ),
              Text(
                subtitle,
                style: AppFonts.geist(
                  fontSize: 12,
                  color: AppColors.ctText2,
                ),
              ),
            ],
          ),
          const Spacer(),
          ...actions.expand((w) sync* {
            yield w;
            if (w != actions.last) yield const SizedBox(width: 8);
          }),
        ],
      ),
    );
  }
}
