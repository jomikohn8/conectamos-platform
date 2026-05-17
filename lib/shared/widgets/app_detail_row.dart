import 'package:flutter/material.dart';
import '../../core/theme/text_styles.dart';

class AppDetailRow extends StatelessWidget {
  const AppDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.prefixIcon,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final String label;
  final Widget value;
  final Widget? prefixIcon;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    Widget labelWidget = Text(label, style: AppTextStyles.bodySmall);

    if (prefixIcon != null) {
      labelWidget = Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          prefixIcon!,
          const SizedBox(width: 6),
          labelWidget,
        ],
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            labelWidget,
            const SizedBox(width: 12),
            Flexible(child: value),
          ],
        ),
      ),
    );
  }
}
