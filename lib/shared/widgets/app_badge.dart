import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

enum AppBadgeVariant { ok, warn, danger, info, neutral, teal, purple, orange }

class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.prefixIcon,
    this.dot = false,
  });

  final String label;
  final AppBadgeVariant variant;
  final Widget? prefixIcon;
  final bool dot;

  Color get _bgColor {
    switch (variant) {
      case AppBadgeVariant.ok:      return AppColors.ctOkBg;
      case AppBadgeVariant.warn:    return AppColors.ctWarnBg;
      case AppBadgeVariant.danger:  return AppColors.ctRedBg;
      case AppBadgeVariant.info:    return AppColors.ctInfoBg;
      case AppBadgeVariant.neutral: return AppColors.ctSurface2;
      case AppBadgeVariant.teal:    return AppColors.ctTealLight;
      case AppBadgeVariant.purple:  return AppColors.ctPurpleBg;
      case AppBadgeVariant.orange:  return AppColors.ctOrangeBg;
    }
  }

  Color get _textColor {
    switch (variant) {
      case AppBadgeVariant.ok:      return AppColors.ctOkText;
      case AppBadgeVariant.warn:    return AppColors.ctWarnText;
      case AppBadgeVariant.danger:  return AppColors.ctRedText;
      case AppBadgeVariant.info:    return AppColors.ctInfoText;
      case AppBadgeVariant.neutral: return AppColors.ctText2;
      case AppBadgeVariant.teal:    return AppColors.ctTealText;
      case AppBadgeVariant.purple:  return AppColors.ctPurpleText;
      case AppBadgeVariant.orange:  return AppColors.ctOrangeText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _textColor;

    final children = <Widget>[];

    if (dot) {
      children.add(Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: textColor,
          shape: BoxShape.circle,
        ),
      ));
      children.add(const SizedBox(width: 5));
    } else if (prefixIcon != null) {
      children.add(prefixIcon!);
      children.add(const SizedBox(width: 4));
    }

    children.add(Text(
      label,
      style: AppTextStyles.badge.copyWith(color: textColor),
    ));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: children,
      ),
    );
  }
}
