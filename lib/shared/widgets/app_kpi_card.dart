import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

class AppKpiCard extends StatefulWidget {
  const AppKpiCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.prefixIcon,
    this.accentColor,
    this.onTap,
  });

  final String label;
  final String value;
  final String? subtitle;
  final Widget? prefixIcon;
  final Color? accentColor;
  final VoidCallback? onTap;

  @override
  State<AppKpiCard> createState() => _AppKpiCardState();
}

class _AppKpiCardState extends State<AppKpiCard> {
  bool _hovered = false;

  Color get _effectiveAccent => widget.accentColor ?? AppColors.ctTeal;

  Color get _borderColor =>
      (_hovered && widget.onTap != null) ? AppColors.ctTeal : AppColors.ctBorder;

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      decoration: BoxDecoration(
        color: AppColors.ctSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.prefixIcon != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: widget.prefixIcon!,
                  ),
                Text(widget.label, style: AppTextStyles.kpiLabel),
                const SizedBox(height: 4),
                Text(widget.value, style: AppTextStyles.kpiValue),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(widget.subtitle!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
          // Accent bar — bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: _effectiveAccent,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
