import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/permissions_provider.dart';
import '../../core/providers/tenant_provider.dart';
import '../../core/theme/app_theme.dart';

// ── Providers globales ────────────────────────────────────────────────────────

/// Estado de colapso del sidebar.
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Providers para acciones y metadata de cada pantalla.
final topbarTitleProvider    = StateProvider<String>((ref) => '');
final topbarSubtitleProvider = StateProvider<String?>((ref) => null);
final topbarActionsProvider  = StateProvider<List<Widget>>((ref) => []);

/// Display name del tenant activo para la UI (usa el notifier real).
final activeTenantProvider = Provider<String>((ref) {
  return ref.watch(currentTenantProvider);
});

// ── AppShell ──────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final email = ref.read(currentUserEmailProvider);
      if (email.isNotEmpty) {
        ref.read(tenantNotifierProvider.notifier).load(email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Covers fresh-login case: currentUserProvider is a synchronous Provider
    // that caches null and is never invalidated by auth changes.
    // Listening here ensures load() is called when sign-in completes.
    ref.listen(authStateProvider, (prev, next) {
      next.whenData((authState) {
        if (authState.event == AuthChangeEvent.signedIn) {
          final email = authState.session?.user.email ?? '';
          if (email.isNotEmpty) {
            ref.read(tenantNotifierProvider.notifier).load(email);
          }
        }
      });
    });
    return Scaffold(
      backgroundColor: AppColors.ctBg,
      body: Column(
        children: [
          const _Topbar(),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Sidebar(),
                Expanded(
                  child: Column(
                    children: [
                      // Cada pantalla gestiona su propio scroll internamente
                      Expanded(child: widget.child),
                      const _Footer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TOPBAR ────────────────────────────────────────────────────────────────────

class _Topbar extends ConsumerWidget {
  const _Topbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed = ref.watch(sidebarCollapsedProvider);
    final email     = ref.watch(currentUserEmailProvider);

    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.ctNavy,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          // Botón colapsar / expandir sidebar
          _TopbarIconBtn(
            icon: collapsed ? Icons.menu_rounded : Icons.menu_open_rounded,
            tooltip: collapsed ? 'Expandir sidebar' : 'Colapsar sidebar',
            onTap: () => ref
                .read(sidebarCollapsedProvider.notifier)
                .state = !collapsed,
          ),
          const SizedBox(width: 10),

          // Logo: isotipo + wordmark
          SvgPicture.asset(
            'assets/images/Conectamos-Isotipo.svg',
            height: 22,
            fit: BoxFit.contain,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: AppFonts.onest(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
              children: const [
                TextSpan(
                  text: 'Conectam',
                  style: TextStyle(fontFamily: 'Geist', color: Colors.white),
                ),
                TextSpan(
                  text: 'OS',
                  style: TextStyle(fontFamily: 'Geist', color: AppColors.ctTeal),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Chip/dropdown de tenant
          if (email == 'miguel@conectamos.mx')
            const _TenantDropdown()
          else
            _TenantChip(name: ref.watch(activeTenantDisplayProvider)),
          const SizedBox(width: 8),

          // Divider vertical
          Container(width: 1, height: 20, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(width: 12),

          // Avatar + email con menú desplegable
          _UserMenu(email: email),
        ],
      ),
    );
  }
}

// ── Tenant chip (otros usuarios) ──────────────────────────────────────────────

class _TenantChip extends StatelessWidget {
  const _TenantChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    if (name.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        name,
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ── Tenant dropdown (superadmin) ──────────────────────────────────────────────

class _TenantDropdown extends ConsumerWidget {
  const _TenantDropdown();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTenants = ref.watch(allTenantsProvider);
    final active     = ref.watch(activeTenantInfoProvider);

    if (allTenants.isEmpty) {
      return _TenantChip(name: active?.displayName ?? '');
    }

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.ctSurface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.ctBorder),
          ),
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      child: PopupMenuButton<TenantInfo>(
        offset: const Offset(0, 44),
        onSelected: (t) =>
            ref.read(tenantNotifierProvider.notifier).select(t),
        itemBuilder: (_) => allTenants
            .map(
              (t) => PopupMenuItem<TenantInfo>(
                value: t,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t.displayName,
                        style: TextStyle(
                          fontFamily: 'Geist',
                          fontSize: 13,
                          fontWeight: t.id == active?.id
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: AppColors.ctText,
                        ),
                      ),
                    ),
                    if (t.id == active?.id)
                      const Icon(Icons.check_rounded,
                          size: 14, color: AppColors.ctTeal),
                  ],
                ),
              ),
            )
            .toList(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  active?.displayName ?? '…',
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Botón de icono en topbar ───────────────────────────────────────────────────

class _TopbarIconBtn extends StatefulWidget {
  const _TopbarIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_TopbarIconBtn> createState() => _TopbarIconBtnState();
}

class _TopbarIconBtnState extends State<_TopbarIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withValues(alpha: 0.08) : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Icon(widget.icon, size: 20, color: Colors.white.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }
}

// ── Menú de usuario ───────────────────────────────────────────────────────────

enum _UserMenuAction { profile, accountSettings, signOut }

class _UserMenu extends ConsumerWidget {
  const _UserMenu({required this.email});
  final String email;

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    _UserMenuAction action,
  ) async {
    switch (action) {
      case _UserMenuAction.profile:
        // TODO: navegar a perfil
        break;
      case _UserMenuAction.accountSettings:
        // TODO: navegar a configuración de cuenta
        break;
      case _UserMenuAction.signOut:
        if (kMockMode) {
          if (context.mounted) context.go('/login');
        } else {
          await Supabase.instance.client.auth.signOut();
          if (context.mounted) context.go('/login');
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'U';

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.ctSurface,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.ctBorder),
          ),
          menuPadding: const EdgeInsets.symmetric(vertical: 6),
        ),
      ),
      child: PopupMenuButton<_UserMenuAction>(
        offset: const Offset(0, 44),
        constraints: const BoxConstraints(minWidth: 200),
        onSelected: (action) => _handleAction(context, ref, action),
        itemBuilder: (context) => [
          // Encabezado: email no clickeable
          PopupMenuItem<_UserMenuAction>(
            enabled: false,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              email,
              style: const TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                color: AppColors.ctText2,
              ),
            ),
          ),
          const PopupMenuDivider(height: 1),

          // Mi perfil
          _buildMenuItem(
            value: _UserMenuAction.profile,
            icon: Icons.person_outline_rounded,
            label: 'Mi perfil',
          ),

          // Configuración de cuenta
          _buildMenuItem(
            value: _UserMenuAction.accountSettings,
            icon: Icons.settings_outlined,
            label: 'Configuración de cuenta',
          ),

          const PopupMenuDivider(height: 1),

          // Cerrar sesión
          _buildMenuItem(
            value: _UserMenuAction.signOut,
            icon: Icons.logout_rounded,
            label: 'Cerrar sesión',
            color: AppColors.ctDanger,
          ),
        ],
        // Trigger: avatar + email + chevron
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Geist',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                email,
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<_UserMenuAction> _buildMenuItem({
    required _UserMenuAction value,
    required IconData icon,
    required String label,
    Color color = AppColors.ctText2,
  }) {
    return PopupMenuItem<_UserMenuAction>(
      value: value,
      height: 40,
      padding: EdgeInsets.zero,
      child: _MenuItemTile(icon: icon, label: label, color: color),
    );
  }
}

class _MenuItemTile extends StatefulWidget {
  const _MenuItemTile({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  State<_MenuItemTile> createState() => _MenuItemTileState();
}

class _MenuItemTileState extends State<_MenuItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: widget.color),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: widget.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── SIDEBAR ───────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collapsed    = ref.watch(sidebarCollapsedProvider);
    final currentRoute = GoRouterState.of(context).matchedLocation;
    final tenantName   = ref.watch(activeTenantDisplayProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: collapsed ? 56 : 220,
      decoration: const BoxDecoration(
        color: AppColors.ctSurface,
        border: Border(right: BorderSide(color: AppColors.ctBorder)),
      ),
      // ClipRect evita que el contenido se desborde durante la animación
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: collapsed ? 56 : 220,
          maxWidth: collapsed ? 56 : 220,
          child: SizedBox(
            width: collapsed ? 56 : 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Nombre del tenant activo (solo cuando el sidebar está expandido)
                if (!collapsed && tenantName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                    child: Text(
                      tenantName,
                      style: const TextStyle(
                        fontFamily: 'Geist',
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ctText3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Nav items con scroll
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _NavSection(
                          label: 'Operaciones',
                          collapsed: collapsed,
                        ),
                        _NavItem(
                          icon: Icons.grid_view_rounded,
                          label: 'Vista general',
                          route: '/overview',
                          currentRoute: currentRoute,
                          collapsed: collapsed,
                        ),
                        _NavItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Conversaciones',
                          route: '/conversations',
                          currentRoute: currentRoute,
                          collapsed: collapsed,
                        ),
                        const SizedBox(height: 4),
                        _NavSection(
                          label: 'Workers',
                          collapsed: collapsed,
                        ),
                        _NavItem(
                          icon: Icons.smart_toy_rounded,
                          label: 'Mis Workers',
                          route: '/workers',
                          currentRoute: currentRoute,
                          collapsed: collapsed,
                        ),
                        if (hasPermission(ref, 'flow_executions', 'execute_dashboard'))
                          _NavItem(
                            icon: Icons.task_alt_outlined,
                            label: 'Tareas',
                            route: '/tareas',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                        if (hasPermission(ref, 'flows', 'view'))
                          _NavItem(
                            icon: Icons.account_tree_outlined,
                            label: 'Flujos de trabajo',
                            route: '/flows',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                        const SizedBox(height: 4),
                        if (hasPermission(ref, 'settings', 'view')) ...[
                          _NavSection(
                            label: 'Configuración',
                            collapsed: collapsed,
                          ),
                          _NavItem(
                            icon: Icons.router_rounded,
                            label: 'Canales',
                            route: '/channels',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                        ],
                        if (hasPermission(ref, 'operators', 'view'))
                          _NavItem(
                            icon: Icons.people_outline_rounded,
                            label: 'Operadores',
                            route: '/operators',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                        if (hasPermission(ref, 'settings', 'view')) ...[
                          _NavItem(
                            icon: Icons.cable_outlined,
                            label: 'Conexiones',
                            route: '/connections',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                          _NavItem(
                            icon: Icons.settings_outlined,
                            label: 'Ajustes',
                            route: '/settings',
                            currentRoute: currentRoute,
                            collapsed: collapsed,
                          ),
                        ],
                        const SizedBox(height: 4),
                        _NavSection(
                          label: 'Próximamente',
                          collapsed: collapsed,
                        ),
                        _DisabledNavItem(
                          icon: Icons.bar_chart_rounded,
                          label: 'Dashboards',
                          collapsed: collapsed,
                        ),
                        _DisabledNavItem(
                          icon: Icons.group_work_outlined,
                          label: 'Catálogo',
                          collapsed: collapsed,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ── Label de sección ──────────────────────────────────────────────────────────

class _NavSection extends StatelessWidget {
  const _NavSection({required this.label, required this.collapsed});
  final String label;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Container(height: 1, color: AppColors.ctBorder),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 3),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.ctText3,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.collapsed,
  });
  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool collapsed;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  bool get _isActive =>
      widget.currentRoute == widget.route ||
      widget.currentRoute.startsWith('${widget.route}/');

  @override
  Widget build(BuildContext context) {
    final content = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.route),
        child: widget.collapsed
            ? _buildCollapsed()
            : _buildExpanded(),
      ),
    );

    // Tooltip solo cuando está colapsado
    if (widget.collapsed) {
      return Tooltip(
        message: widget.label,
        preferBelow: false,
        waitDuration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: AppColors.ctNavy,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Geist',
          fontSize: 12,
          color: Colors.white,
        ),
        child: content,
      );
    }
    return content;
  }

  // Ítem colapsado: solo ícono centrado
  Widget _buildCollapsed() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        color: _isActive
            ? AppColors.ctTealLight
            : _hovered
                ? AppColors.ctSurface2
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(
        widget.icon,
        size: 18,
        color: _isActive
            ? AppColors.ctTealDark
            : _hovered
                ? AppColors.ctText2
                : AppColors.ctText3,
      ),
    );
  }

  // Ítem expandido: ícono + texto, borde izquierdo si activo
  Widget _buildExpanded() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _isActive
            ? AppColors.ctTealLight
            : _hovered
                ? AppColors.ctSurface2
                : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: _isActive
            ? const Border(
                left: BorderSide(color: AppColors.ctTeal, width: 2),
              )
            : null,
      ),
      child: Row(
        children: [
          Icon(
            widget.icon,
            size: 16,
            color: _isActive
                ? AppColors.ctTealDark
                : _hovered
                    ? AppColors.ctText2
                    : AppColors.ctText3,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.label,
              style: TextStyle(
                fontFamily: 'Geist',
                fontSize: 12,
                fontWeight:
                    _isActive ? FontWeight.w600 : FontWeight.w500,
                color: _isActive
                    ? AppColors.ctTealDark
                    : _hovered
                        ? AppColors.ctText
                        : AppColors.ctText2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Disabled nav item (Coming Soon) ───────────────────────────────────────────

class _DisabledNavItem extends StatefulWidget {
  const _DisabledNavItem({
    required this.icon,
    required this.label,
    required this.collapsed,
  });
  final IconData icon;
  final String label;
  final bool collapsed;

  @override
  State<_DisabledNavItem> createState() => _DisabledNavItemState();
}

class _DisabledNavItemState extends State<_DisabledNavItem> {
  bool _hovered = false;

  Widget _buildCollapsed() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      width: 44,
      height: 36,
      decoration: BoxDecoration(
        color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.4,
        child: Icon(widget.icon, size: 18, color: AppColors.ctText3),
      ),
    );
  }

  Widget _buildExpanded() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _hovered ? AppColors.ctSurface2 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Opacity(
        opacity: 0.4,
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: AppColors.ctText3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ctText2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Tooltip(
      message: 'Próximamente',
      preferBelow: false,
      waitDuration: Duration.zero,
      decoration: BoxDecoration(
        color: AppColors.ctNavy,
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(
        fontFamily: 'Geist',
        fontSize: 12,
        color: Colors.white,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.forbidden,
        child: widget.collapsed ? _buildCollapsed() : _buildExpanded(),
      ),
    );

    return content;
  }
}

// ── FOOTER ────────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        height: 36,
        color: AppColors.ctNavy,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/Conectamos-Isotipo.svg',
                height: 14,
                fit: BoxFit.contain,
                colorFilter: const ColorFilter.mode(
                  AppColors.ctTeal,
                  BlendMode.srcIn,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Built with ❤️  Powered by 🤖',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 11,
                  color: AppColors.ctTeal.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
