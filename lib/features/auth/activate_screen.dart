import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_theme.dart';

class ActivateScreen extends StatefulWidget {
  const ActivateScreen({super.key, required this.token});
  final String token;

  @override
  State<ActivateScreen> createState() => _ActivateScreenState();
}

class _ActivateScreenState extends State<ActivateScreen> {
  bool _loadingToken = true;
  String? _tokenError;
  Map<String, dynamic>? _inviteData;

  final _nameCtrl    = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _submitting = false;
  String? _submitError;
  bool _success = false;

  // Fallback for uncaught build errors
  String? _renderFallbackMsg;

  @override
  void initState() {
    super.initState();
    print('[Activate] token: ${widget.token}');
    _validateToken();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _validateToken() async {
    try {
      print('[Activate] calling GET /iam/invite/${widget.token}');
      final res =
          await ApiClient.instance.get('/iam/invite/${widget.token}');
      print('[Activate] response: ${res.data}');
      if (!mounted) return;
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(res.data as Map);
      } catch (castErr) {
        print('[Activate] cast error: $castErr');
        data = {};
      }
      setState(() {
        _inviteData = data;
        _loadingToken = false;
      });
    } on DioException catch (e) {
      print('[Activate] DioException: $e — response: ${e.response?.data}');
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _tokenError = detail ?? 'Este enlace no es válido o ha expirado';
        _loadingToken = false;
      });
    } catch (e) {
      print('[Activate] error: $e');
      if (!mounted) return;
      setState(() {
        _tokenError = 'Error al validar el enlace: $e';
        _loadingToken = false;
      });
    }
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    if (name.isEmpty) {
      setState(() => _submitError = 'Ingresa tu nombre completo');
      return;
    }
    if (pass.length < 8) {
      setState(() =>
          _submitError = 'La contraseña debe tener al menos 8 caracteres');
      return;
    }
    if (pass != confirm) {
      setState(() => _submitError = 'Las contraseñas no coinciden');
      return;
    }

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      await ApiClient.instance.post(
        '/iam/invite/${widget.token}/accept',
        data: {
          'password': pass,
          'nombre':   _nameCtrl.text.trim(),
          'telefono': _phoneCtrl.text.trim(),
        },
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _success = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) context.go('/login');
    } on DioException catch (e) {
      print('[Activate] submit DioException: $e — response: ${e.response?.data}');
      if (!mounted) return;
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : e.response?.data?.toString();
      setState(() {
        _submitError =
            detail ?? 'Error al activar la cuenta. Intenta nuevamente.';
        _submitting = false;
      });
    } catch (e) {
      print('[Activate] submit error: $e');
      if (!mounted) return;
      setState(() {
        _submitError = 'Error al activar la cuenta: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_renderFallbackMsg != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0B132B),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              'Error de renderizado:\n$_renderFallbackMsg',
              style: const TextStyle(color: Colors.white, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    try {
      return _buildScaffold(context);
    } catch (e) {
      print('[Activate] build error: $e');
      // Schedule setState after build to avoid setState-during-build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _renderFallbackMsg = e.toString());
      });
      return const Scaffold(
        backgroundColor: Color(0xFF0B132B),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2DD4BF)),
        ),
      );
    }
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo navy
          Positioned.fill(child: Container(color: const Color(0xFF0B132B))),

          // Blob teal superior
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
          if (_loadingToken)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            )
          else if (_tokenError != null)
            _buildCrashError(_tokenError!)
          else if (_success)
            _buildSuccess()
          else
            _buildForm(),
        ],
      ),
    );
  }

  Widget _buildCrashError(String message) {
    return Column(
      children: [
        const Icon(Icons.link_off_rounded, size: 48, color: Color(0xFF9CA3AF)),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Geist',
            fontSize: 14,
            color: AppColors.ctRedText,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.go('/login'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.ctBorder2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: const Text(
              'Ir al inicio de sesión',
              style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 14,
                  color: AppColors.ctText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const Icon(Icons.check_circle_rounded,
            size: 48, color: AppColors.ctOk),
        const SizedBox(height: 16),
        Text(
          'Cuenta activada. Inicia sesión.',
          textAlign: TextAlign.center,
          style: GoogleFonts.onest(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.ctOkText,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Redirigiendo...',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 13,
            color: AppColors.ctText2,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    final tenantName =
        _inviteData?['tenant_name']?.toString() ?? '';
    final role = _inviteData?['role']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activa tu cuenta',
          style: TextStyle(
            fontFamily: 'Geist',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        if (tenantName.isNotEmpty || role.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 13,
                    color: Color(0xFF6B7280)),
                children: [
                  if (tenantName.isNotEmpty)
                    TextSpan(text: 'Tenant: $tenantName'),
                  if (tenantName.isNotEmpty && role.isNotEmpty)
                    const TextSpan(text: '  ·  '),
                  if (role.isNotEmpty) TextSpan(text: 'Rol: $role'),
                ],
              ),
            ),
          )
        else
          const SizedBox(height: 20),

        // Nombre completo
        _Field(
          label: 'Nombre completo',
          controller: _nameCtrl,
          placeholder: 'Juan García',
        ),
        const SizedBox(height: 16),

        // Teléfono
        _Field(
          label: 'Teléfono (opcional)',
          controller: _phoneCtrl,
          placeholder: '+52 55 1234 5678',
        ),
        const SizedBox(height: 16),

        // Contraseña
        _Field(
          label: 'Contraseña',
          controller: _passCtrl,
          placeholder: '••••••••',
          obscureText: !_showPass,
          suffix: IconButton(
            icon: Icon(
              _showPass
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: () => setState(() => _showPass = !_showPass),
            splashRadius: 16,
          ),
        ),
        const SizedBox(height: 16),

        // Confirmar contraseña
        _Field(
          label: 'Confirmar contraseña',
          controller: _confirmCtrl,
          placeholder: '••••••••',
          obscureText: !_showConfirm,
          onSubmit: _submitting ? null : _submit,
          suffix: IconButton(
            icon: Icon(
              _showConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF9CA3AF),
            ),
            onPressed: () =>
                setState(() => _showConfirm = !_showConfirm),
            splashRadius: 16,
          ),
        ),
        const SizedBox(height: 24),

        // Botón activar
        _ActivateButton(
          loading: _submitting,
          onTap: _submitting ? null : _submit,
        ),

        // Error
        if (_submitError != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                    _submitError!,
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
    );
  }
}

// ── Campo de formulario ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.placeholder,
    this.obscureText = false,
    this.onSubmit,
    this.suffix,
  });
  final String label;
  final TextEditingController controller;
  final String placeholder;
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

// ── Botón activar ─────────────────────────────────────────────────────────────

class _ActivateButton extends StatefulWidget {
  const _ActivateButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_ActivateButton> createState() => _ActivateButtonState();
}

class _ActivateButtonState extends State<_ActivateButton> {
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
                  'Activar cuenta',
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
