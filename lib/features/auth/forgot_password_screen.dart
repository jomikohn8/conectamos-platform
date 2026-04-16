import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ApiClient.instance.post(
        '/iam/password-reset',
        data: {'email': email},
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _sent = true;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _error = detail ?? 'Error al enviar el enlace. Intenta nuevamente.';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al enviar el enlace. Intenta nuevamente.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo navy
          Positioned.fill(child: Container(color: const Color(0xFF0B132B))),

          // Blob teal superior izquierda
          Positioned(
            top: -300,
            left: -400,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 120, sigmaY: 120),
              child: Container(
                width: 900,
                height: 900,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66E2D0).withValues(alpha: 0.7),
                ),
              ),
            ),
          ),

          // Blob teal centro
          Positioned(
            top: -50,
            left: -200,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 700,
                height: 700,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF66E2D0).withValues(alpha: 0.55),
                ),
              ),
            ),
          ),

          // Gradiente oscuro desde arriba
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 300,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0B132B), Colors.transparent],
                ),
              ),
            ),
          ),

          // Contenido
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildCard(),
                    ),
                  ),
                ),
                _Footer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/images/Conectamos-Isotipo.svg',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Conectam',
                  style: GoogleFonts.onest(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF111827),
                  ),
                ),
                TextSpan(
                  text: 'OS',
                  style: GoogleFonts.onest(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2DD4BF),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_sent) _buildSuccess() else _buildForm(),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recuperar contraseña',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ingresa tu correo y te enviaremos un enlace para restablecer tu contraseña',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // Email
        _Field(
          label: 'Correo electrónico',
          controller: _emailCtrl,
          placeholder: 'tu@empresa.com',
          keyboardType: TextInputType.emailAddress,
          onSubmit: _loading ? null : _submit,
        ),
        const SizedBox(height: 24),

        // Botón enviar
        _PrimaryButton(
          label: 'Enviar enlace',
          loading: _loading,
          onTap: _loading ? null : _submit,
        ),

        // Error
        if (_error != null) ...[
          const SizedBox(height: 16),
          _ErrorBox(message: _error!),
        ],

        const SizedBox(height: 20),

        // Volver al login
        Center(
          child: GestureDetector(
            onTap: () => context.go('/login'),
            child: const Text(
              'Volver al inicio de sesión',
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctTeal,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.mark_email_read_rounded,
            size: 48, color: AppColors.ctOk),
        const SizedBox(height: 16),
        Text(
          'Revisa tu correo',
          textAlign: TextAlign.center,
          style: GoogleFonts.onest(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ctOkText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Te enviamos el enlace para restablecer tu contraseña. Revisa también la carpeta de spam.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => context.go('/login'),
          child: const Text(
            'Volver al inicio de sesión',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: AppColors.ctTeal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Campo de formulario ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.onSubmit,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          onSubmitted: onSubmit != null ? (_) => onSubmit!() : null,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(
              fontFamily: 'Geist',
              fontSize: 14,
              color: Color(0xFF9CA3AF),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: AppColors.ctTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botón primario ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });
  final String label;
  final bool loading;
  final VoidCallback? onTap;

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
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          height: 46,
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? AppColors.ctTeal.withValues(alpha: 0.55)
                : _hovered
                    ? AppColors.ctTealDark
                    : AppColors.ctTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.ctNavy),
                  ),
                )
              : Text(
                  widget.label,
                  style: AppFonts.onest(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ctNavy,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── Caja de error ─────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.ctRedBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 16, color: AppColors.ctRedText),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                color: AppColors.ctRedText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Footer ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 24, top: 12),
      child: Center(
        child: Text(
          'Built with ❤️  Powered by AI',
          style: GoogleFonts.onest(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
