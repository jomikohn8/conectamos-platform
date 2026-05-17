import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

// ── Enums ──────────────────────────────────────────────────────────────────

enum AppButtonVariant { primary, teal, ghost, outline, danger }

enum AppButtonSize { normal, sm }

// ── Widget ─────────────────────────────────────────────────────────────────

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.normal,
    this.prefixIcon,
    this.suffixIcon,
    this.isLoading = false,
    this.isDisabled = false,
    this.expand = false,
  });

  final String label;
  final VoidCallback onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isLoading;
  final bool isDisabled;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _hovered = false;

  bool get _interactive => !widget.isLoading && !widget.isDisabled;

  // ── Color helpers ──────────────────────────────────────────────────────

  Color get _bgColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.ctNavy;
      case AppButtonVariant.teal:
        return AppColors.ctTeal;
      case AppButtonVariant.ghost:
        return _hovered && _interactive ? AppColors.ctSurface2 : Colors.transparent;
      case AppButtonVariant.outline:
        return Colors.transparent;
      case AppButtonVariant.danger:
        return AppColors.ctDanger;
    }
  }

  Color get _textColor {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return AppColors.ctTeal;
      case AppButtonVariant.teal:
        return AppColors.ctNavy;
      case AppButtonVariant.ghost:
        return AppColors.ctInk700;
      case AppButtonVariant.outline:
        return AppColors.ctInk700;
      case AppButtonVariant.danger:
        return Colors.white;
    }
  }

  Color? get _borderColor {
    if (widget.variant == AppButtonVariant.outline) return AppColors.ctBorder;
    return null;
  }

  double get _hoverOpacity {
    if (!_hovered || !_interactive) return 1.0;
    switch (widget.variant) {
      case AppButtonVariant.primary:
      case AppButtonVariant.teal:
        return 0.92;
      case AppButtonVariant.ghost:
        return 1.0; // bg color change handles hover
      case AppButtonVariant.outline:
      case AppButtonVariant.danger:
        return 0.88;
    }
  }

  // ── Size helpers ───────────────────────────────────────────────────────

  double get _height => widget.size == AppButtonSize.normal ? 42.0 : 32.0;

  double get _hPadding => widget.size == AppButtonSize.normal ? 18.0 : 14.0;

  double get _fontSize => widget.size == AppButtonSize.normal ? 13.0 : 12.0;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontFamily: 'Geist',
      fontSize: _fontSize,
      fontWeight: FontWeight.w700,
      color: _textColor,
      letterSpacing: -0.01,
      height: 1.0,
    );

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(_textColor),
        ),
      );
    } else {
      final children = <Widget>[
        if (widget.prefixIcon != null) ...[
          widget.prefixIcon!,
          const SizedBox(width: 6),
        ],
        Text(widget.label, style: textStyle),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: 6),
          widget.suffixIcon!,
        ],
      ];

      content = children.length == 1
          ? children.first
          : Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: children,
            );
    }

    Widget button = MouseRegion(
      cursor:
          _interactive ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _interactive ? widget.onPressed : null,
        child: Opacity(
          opacity: _hoverOpacity,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: _height,
            width: widget.expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: _hPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _bgColor,
              borderRadius: BorderRadius.circular(10),
              border: _borderColor != null
                  ? Border.all(color: _borderColor!, width: 1)
                  : null,
            ),
            child: content,
          ),
        ),
      ),
    );

    if (widget.isDisabled) {
      button = Opacity(opacity: 0.45, child: button);
    }

    return button;
  }
}
