import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/colors.dart';

// ── Background ────────────────────────────────────────────────────────────────

class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: Container(color: AppColors.ctNavy)),

        // Blob teal 1 — top-left large
        Positioned(
          top: -320, left: -360,
          child: _Blob(width: 880, height: 880, color: AppColors.ctTealHover, opacity: 0.55, blur: 110, circle: true),
        ),
        // Blob teal 2 — center-left
        Positioned(
          top: 120, left: -240,
          child: _Blob(width: 640, height: 640, color: AppColors.ctTealHover, opacity: 0.38, blur: 100, circle: true),
        ),
        // Blob steel — top-right
        Positioned(
          top: -160, right: -200,
          child: _Blob(width: 700, height: 520, color: AppColors.ctInk700, opacity: 0.60, blur: 120, circle: false),
        ),
        // Blob warm teal — bottom-right
        Positioned(
          bottom: -260, right: -200,
          child: _Blob(width: 640, height: 520, color: const Color(0xFF5BC0BE), opacity: 0.22, blur: 130, circle: false),
        ),

        // Top fade
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xE80B132B), Colors.transparent],
              ),
            ),
          ),
        ),

        child,
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.width, required this.height,
    required this.color, required this.opacity, required this.blur,
    required this.circle,
  });
  final double width, height, opacity, blur;
  final Color color;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: width, height: height,
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(260),
        ),
      ),
    );
  }
}

// ── Topbar ────────────────────────────────────────────────────────────────────

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            'assets/images/Conectamos-Logotipo.svg',
            height: 22,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          _HelpLink(),
        ],
      ),
    );
  }
}

class _HelpLink extends StatefulWidget {
  @override
  State<_HelpLink> createState() => _HelpLinkState();
}

class _HelpLinkState extends State<_HelpLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: _hovered
                ? AppColors.ctTeal.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.12),
          ),
          color: _hovered
              ? AppColors.ctTeal.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 14,
                color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.75)),
            const SizedBox(width: 6),
            Text(
              'Soporte',
              style: TextStyle(
                fontFamily: 'Geist', fontSize: 13,
                color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.75),
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 18, 40, 22),
      child: Center(
        child: Text(
          'Built with ❤️ Powered by 🤖',
          style: TextStyle(
            fontFamily: 'Onest',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.65),
          ),
        ),
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child, this.maxWidth = 460});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(18)),
          boxShadow: [
            BoxShadow(
              color: Color(0x590B132B),
              blurRadius: 64,
              offset: Offset(0, 32),
            ),
            BoxShadow(
              color: Color(0x400B132B),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
        child: child,
      ),
    );
  }
}

// ── Card head ─────────────────────────────────────────────────────────────────

class AuthCardHead extends StatelessWidget {
  const AuthCardHead({
    super.key,
    required this.title,
    this.titleAccent,
    this.subtitle,
  });
  final String title;
  final String? titleAccent;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final String before = titleAccent != null
        ? title.substring(0, title.lastIndexOf(titleAccent!))
        : title;
    final String accent = titleAccent ?? '';

    return Column(
      children: [
        // Isotipo badge
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.ctInk700, AppColors.ctNavy],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.ctNavy.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: SvgPicture.asset(
              'assets/images/Conectamos-Isotipo.svg',
              width: 26,
              colorFilter: const ColorFilter.mode(AppColors.ctTeal, BlendMode.srcIn),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Title
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Onest',
              fontWeight: FontWeight.w700,
              fontSize: 22,
              height: 1.2,
              letterSpacing: -0.6,
              color: AppColors.ctNavy,
            ),
            children: [
              TextSpan(text: before),
              if (accent.isNotEmpty)
                TextSpan(
                  text: accent,
                  style: const TextStyle(color: Color(0xFF5BC0BE)),
                ),
            ],
          ),
        ),

        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 13.5,
              color: Color(0xFF6E7273),
              letterSpacing: -0.1,
            ),
          ),
        ],
        const SizedBox(height: 28),
      ],
    );
  }
}

// ── Field ─────────────────────────────────────────────────────────────────────

class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.controller,
    required this.placeholder,
    this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.error,
    this.onSubmit,
    this.autofocus = false,
    this.inputAction,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final IconData? icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final String? error;
  final VoidCallback? onSubmit;
  final bool autofocus;
  final TextInputAction? inputAction;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final FocusNode _focus;
  bool _focused = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode()..addListener(_onFocus);
  }

  void _onFocus() => setState(() => _focused = _focus.hasFocus);

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = widget.error != null;

    final Color borderColor = hasError
        ? const Color(0xFFFCA5A5)
        : _focused
            ? AppColors.ctTeal
            : const Color(0xFFE3E6EB);

    final List<BoxShadow>? shadows = _focused && !hasError
        ? [BoxShadow(color: AppColors.ctTeal.withValues(alpha: 0.20), blurRadius: 0, spreadRadius: 3)]
        : hasError
            ? [BoxShadow(color: const Color(0xFFE24C4B).withValues(alpha: 0.12), blurRadius: 0, spreadRadius: 3)]
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.ctNavy,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: 18,
                  color: _focused ? AppColors.ctInk700 : const Color(0xFF9AA0A3),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _focus,
                  obscureText: widget.isPassword && _obscure,
                  keyboardType: widget.keyboardType,
                  autofocus: widget.autofocus,
                  textInputAction: widget.inputAction,
                  onSubmitted: widget.onSubmit != null ? (_) => widget.onSubmit!() : null,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 14,
                    color: AppColors.ctNavy,
                    letterSpacing: -0.1,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: const TextStyle(
                      fontFamily: 'Geist',
                      fontSize: 14,
                      color: Color(0xFFA9B1BC),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (widget.isPassword)
                IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 18,
                    color: const Color(0xFF9AA0A3),
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                const SizedBox(width: 14),
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 13, color: Color(0xFFB42E2D)),
              const SizedBox(width: 5),
              Text(
                widget.error!,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12.5,
                  color: Color(0xFFB42E2D),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Primary button ────────────────────────────────────────────────────────────

class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onTap,
    this.trailingIcon,
  });
  final String label;
  final bool loading;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool disabled = widget.onTap == null || widget.loading;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.loading ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: disabled
                ? AppColors.ctTeal.withValues(alpha: 0.55)
                : _hovered
                    ? AppColors.ctTealHover
                    : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(12),
            boxShadow: disabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 3,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inset highlight (simulated with gradient)
              if (!disabled)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [Color(0x1FFFFFFF), Color(0x00FFFFFF)],
                      ),
                    ),
                  ),
                ),
              if (widget.loading)
                const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctNavy),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.ctNavy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (widget.trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(widget.trailingIcon, size: 16, color: AppColors.ctNavy),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alert ─────────────────────────────────────────────────────────────────────

class AuthAlert extends StatelessWidget {
  const AuthAlert.error({super.key, required this.message}) : _isError = true;
  const AuthAlert.info({super.key, required this.message}) : _isError = false;

  final String message;
  final bool _isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _isError ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _isError ? const Color(0xFFFECACA) : AppColors.ctTealLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: _isError ? const Color(0xFFB42E2D) : AppColors.ctTealText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                letterSpacing: -0.1,
                color: _isError ? const Color(0xFFB42E2D) : AppColors.ctTealText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success block ─────────────────────────────────────────────────────────────

class AuthSuccessBlock extends StatefulWidget {
  const AuthSuccessBlock({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.check_circle_outline_rounded,
  });
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<AuthSuccessBlock> createState() => _AuthSuccessBlockState();
}

class _AuthSuccessBlockState extends State<AuthSuccessBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, child) => Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 1.0 + _pulse.value * 0.25,
                child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.ctTeal
                          .withValues(alpha: (1.0 - _pulse.value) * 0.35),
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
          child: Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE6FAF5),
            ),
            child: Icon(widget.icon, size: 28, color: const Color(0xFF0F9E82)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.title,
          style: const TextStyle(
            fontFamily: 'Onest',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
            color: AppColors.ctNavy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 13.5,
            color: Color(0xFF6E7273),
            letterSpacing: -0.1,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
