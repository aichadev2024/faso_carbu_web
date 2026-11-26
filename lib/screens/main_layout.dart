import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/logo.dart';

class _NavItem {
  const _NavItem(this.route, this.label, this.icon, this.activeIcon);
  final String route;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _mainNav = [
  _NavItem('/dashboard', 'Tableau de bord', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
  _NavItem('/demandes', 'Demandes', Icons.assignment_outlined, Icons.assignment_rounded),
  _NavItem('/tickets', 'Tickets', Icons.confirmation_number_outlined, Icons.confirmation_number_rounded),
  _NavItem('/consommations', 'Consommations', Icons.local_drink_outlined, Icons.local_drink_rounded),
  _NavItem('/rapports', 'Rapports', Icons.insert_chart_outlined_rounded, Icons.insert_chart_rounded),
];

const _manageNav = [
  _NavItem('/users', 'Utilisateurs', Icons.group_outlined, Icons.group_rounded),
  _NavItem('/stations', 'Stations', Icons.local_gas_station_outlined, Icons.local_gas_station_rounded),
  _NavItem('/vehicules', 'Véhicules', Icons.directions_car_outlined, Icons.directions_car_rounded),
];

/// Coquille commune de toutes les pages connectées :
/// barre latérale (ou tiroir sur mobile), barre supérieure, contenu.
class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.child,
    required this.title,
    this.jwtToken = '',
    this.scrollable = true,
  });

  final Widget child;
  final String title;
  final String jwtToken;

  /// Mettre à false si [child] gère lui-même son défilement.
  final bool scrollable;

  static const double _desktopBreakpoint = 1000;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= _desktopBreakpoint;
    final current = ModalRoute.of(context)?.settings.name ?? '';

    final content = scrollable
        ? SingleChildScrollView(
            padding: EdgeInsets.all(isDesktop ? AppSpacing.xxl : AppSpacing.lg),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 1280), child: child),
            ),
          )
        : Padding(
            padding: EdgeInsets.all(isDesktop ? AppSpacing.xxl : AppSpacing.lg),
            child: child,
          );

    return Scaffold(
      drawer: isDesktop ? null : Drawer(width: 280, child: _Sidebar(current: current)),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 264, child: _Sidebar(current: current)),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title, showMenu: !isDesktop),
                Expanded(child: content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget section(String label) => Padding(
          padding: const EdgeInsets.fromLTRB(14, 22, 12, 8),
          child: Text(label, style: t.labelSmall?.copyWith(color: AppColors.textMutedDark, letterSpacing: 1.2)),
        );
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF17181B), Color(0xFF111214)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Logo(size: 36, onDark: true, tagline: 'Gestion du carburant'),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    section('PILOTAGE'),
                    for (final item in _mainNav) _NavTile(item: item, active: current.startsWith(item.route)),
                    section('GESTION'),
                    for (final item in _manageNav) _NavTile(item: item, active: current.startsWith(item.route)),
                  ],
                ),
              ),
              const _SidebarUser(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Carte utilisateur en bas de la barre latérale.
class _SidebarUser extends StatelessWidget {
  const _SidebarUser();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          InitialsAvatar(name: Session.fullName, size: 36),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Session.fullName.isEmpty ? 'Mon compte' : Session.fullName,
                  style: t.titleSmall?.copyWith(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  Session.roleLabel,
                  style: t.bodySmall?.copyWith(color: AppColors.textMutedDark),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout_rounded, size: 19, color: AppColors.sidebarText),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active});
  final _NavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.sidebarText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            gradient: active
                ? LinearGradient(colors: [AppColors.brand.withValues(alpha: 0.24), AppColors.brand.withValues(alpha: 0.03)])
                : null,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            hoverColor: Colors.white.withValues(alpha: 0.05),
            onTap: () {
              if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.pop(context);
              Navigator.pushReplacementNamed(context, item.route, arguments: Session.routeArgs);
            },
            child: Stack(
              children: [
                if (active)
                  Positioned(
                    left: 0,
                    top: 10,
                    bottom: 10,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(color: AppColors.brandOnDark, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Icon(active ? item.activeIcon : item.icon, size: 20, color: active ? AppColors.brandOnDark : color),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: color,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                            ),
                      ),
                    ],
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.showMenu});
  final String title;
  final bool showMenu;

  static const _mois = [
    'janvier', 'février', 'mars', 'avril', 'mai', 'juin', //
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
  ];
  static const _jours = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    final now = DateTime.now();
    final date = '${_jours[now.weekday - 1]} ${now.day} ${_mois[now.month - 1]} ${now.year}';
    final dark = theme.brightness == Brightness.dark;
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (showMenu)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                tooltip: 'Menu',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          SizedBox(width: showMenu ? AppSpacing.xs : AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (wide) Text('FasoCarbu  /  $title', style: t.bodySmall, overflow: TextOverflow.ellipsis),
                Text(title, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          if (wide) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: t.bodySmall?.color),
                const SizedBox(width: 8),
                Text(date, style: t.labelMedium),
              ]),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          IconButton(
            tooltip: dark ? 'Thème clair' : 'Thème sombre',
            onPressed: ThemeController.toggle,
            icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
          ),
          const SizedBox(width: AppSpacing.xs),
          const _UserMenu(),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  const _UserMenu();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return PopupMenuButton<String>(
      tooltip: 'Mon compte',
      offset: const Offset(0, 56),
      onSelected: (v) {
        switch (v) {
          case 'profil':
            Navigator.pushNamed(context, '/profil', arguments: Session.routeArgs);
          case 'password':
            Navigator.pushNamed(context, '/change-password', arguments: Session.routeArgs);
          case 'logout':
            logout(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(Session.fullName.isEmpty ? 'Mon compte' : Session.fullName, style: t.titleSmall),
              Text(Session.email, style: t.bodySmall),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profil',
          child: ListTile(leading: Icon(Icons.person_outline_rounded), title: Text('Mon profil'), dense: true, contentPadding: EdgeInsets.zero),
        ),
        const PopupMenuItem(
          value: 'password',
          child: ListTile(leading: Icon(Icons.lock_outline_rounded), title: Text('Mot de passe'), dense: true, contentPadding: EdgeInsets.zero),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout_rounded, color: AppColors.danger),
            title: Text('Déconnexion', style: TextStyle(color: AppColors.danger)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InitialsAvatar(name: Session.fullName, size: 32),
            if (wide) ...[
              const SizedBox(width: 8),
              Text(Session.prenom.isEmpty ? 'Mon compte' : Session.prenom, style: t.titleSmall),
            ],
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded, size: 18, color: t.bodySmall?.color),
          ],
        ),
      ),
    );
  }
}

/// Logo FasoCarbu (nom conservé pour les écrans existants).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 34});
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) => Logo(size: size, onDark: onDark);
}

Future<void> logout(BuildContext context) async {
  final ok = await confirmDialog(
    context,
    title: 'Se déconnecter ?',
    message: 'Vous devrez saisir à nouveau vos identifiants pour accéder au tableau de bord.',
    confirmLabel: 'Déconnexion',
  );
  if (!ok || !context.mounted) return;
  await Session.clear();
  if (!context.mounted) return;
  Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
}
