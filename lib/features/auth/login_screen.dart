import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _showPass = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (kMockMode) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.go('/');
        return;
      }
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (mounted) context.go('/');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Error al iniciar sesión. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        if (wide) {
          return Row(
            children: [
              Expanded(child: _LeftPane()),
              Expanded(
                child: _RightPane(
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  loading: _loading,
                  showPass: _showPass,
                  error: _error,
                  onTogglePass: () =>
                      setState(() => _showPass = !_showPass),
                  onSignIn: _loading ? null : _signIn,
                ),
              ),
            ],
          );
        }
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _LoginCard(
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              loading: _loading,
              showPass: _showPass,
              error: _error,
              onTogglePass: () =>
                  setState(() => _showPass = !_showPass),
              onSignIn: _loading ? null : _signIn,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Capa base navy
          Positioned.fill(
            child: Container(color: const Color(0xFF0B132B)),
          ),

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

          // Blob teal centro-izquierda
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

          // Blob blanco difuso centro-izquierda
          Positioned(
            top: 100,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 110, sigmaY: 110),
              child: Container(
                width: 600,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(300),
                ),
              ),
            ),
          ),

          // Blob azul-gris superior
          Positioned(
            top: -200,
            left: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(
                width: 800,
                height: 600,
                decoration: BoxDecoration(
                  color: const Color(0xFF3A506B).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(400),
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

          // Contenido encima
          Positioned.fill(
            child: Column(
              children: [
                Expanded(child: _buildContent()),
                const _LoginFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Zona izquierda ────────────────────────────────────────────────────────────

class _LeftPane extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/images/Conectamos-Logotipo.svg',
            height: 36,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Centraliza y automatiza\ntus operaciones',
            style: AppFonts.onest(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Conecta a tus operadores, estructura tu información y toma decisiones en tiempo real.',
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.80),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          ..._kFeatures.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.ctTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      f,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

const _kFeatures = [
  'Gestión de operadores en tiempo real',
  'Flujos de reporte por WhatsApp',
  'Dashboard de métricas operativas',
];

// ── Zona derecha ──────────────────────────────────────────────────────────────

class _RightPane extends StatelessWidget {
  const _RightPane({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.showPass,
    required this.error,
    required this.onTogglePass,
    required this.onSignIn,
  });
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool showPass;
  final String? error;
  final VoidCallback onTogglePass;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: _LoginCard(
          emailCtrl: emailCtrl,
          passCtrl: passCtrl,
          loading: loading,
          showPass: showPass,
          error: error,
          onTogglePass: onTogglePass,
          onSignIn: onSignIn,
        ),
      ),
    );
  }
}

// ── Card de login ─────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.showPass,
    required this.error,
    required this.onTogglePass,
    required this.onSignIn,
  });
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool showPass;
  final String? error;
  final VoidCallback onTogglePass;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
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
          // Isotipo
          SvgPicture.asset(
            'assets/images/Conectamos-Isotipo.svg',
            height: 32,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 12),

          // Título
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Bienvenido a Conectam',
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
          const SizedBox(height: 4),
          const Text(
            'Ingresa tus credenciales para acceder',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 28),

          // Email
          _FormField(
            label: 'Email',
            controller: emailCtrl,
            placeholder: 'tu@empresa.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),

          // Contraseña
          _FormField(
            label: 'Contraseña',
            controller: passCtrl,
            placeholder: '••••••••',
            obscureText: !showPass,
            onSubmit: onSignIn,
            suffix: IconButton(
              icon: Icon(
                showPass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                size: 18,
                color: const Color(0xFF9CA3AF),
              ),
              onPressed: onTogglePass,
              splashRadius: 16,
            ),
          ),
          const SizedBox(height: 24),

          // Botón iniciar sesión
          _LoginButton(loading: loading, onTap: onSignIn),

          // ¿Olvidaste tu contraseña?
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/forgot-password'),
              child: const Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 13,
                  color: AppColors.ctTeal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          // Error
          if (error != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.ctRedBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: AppColors.ctRedText,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 13,
                        color: AppColors.ctRedText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Campo de formulario ───────────────────────────────────────────────────────

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmit,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboardType;
  final bool obscureText;
  final VoidCallback? onSubmit;
  final Widget? suffix;

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
          obscureText: obscureText,
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
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
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
              borderSide: const BorderSide(
                  color: AppColors.ctTeal, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Botón de login ────────────────────────────────────────────────────────────

class _LoginButton extends StatefulWidget {
  const _LoginButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.ctNavy),
                  ),
                )
              : Text(
                  'Iniciar sesión',
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

// ── Footer ────────────────────────────────────────────────────────────────────

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

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
