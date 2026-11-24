import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';

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
      drawer: isDesktop ? null : Drawer(width: 272, child: _Sidebar(current: current)),
      body: Row(
        children: [
          if (isDesktop) SizedBox(width: 248, child: _Sidebar(current: current)),
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
    return Material(
      color: AppColors.sidebar,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 22, 20, 26),
              child: BrandMark(onDark: true),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  for (final item in _mainNav) _NavTile(item: item, active: current.startsWith(item.route)),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 22, 12, 8),
                    child: Text('GESTION', style: t.labelSmall?.copyWith(color: AppColors.textMutedDark)),
                  ),
                  for (final item in _manageNav) _NavTile(item: item, active: current.startsWith(item.route)),
                ],
              ),
            ),
            const Divider(color: AppColors.borderDark),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _NavTile(
                item: const _NavItem('/logout', 'Déconnexion', Icons.logout_rounded, Icons.logout_rounded),
                active: false,
                onTap: () => logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({required this.item, required this.active, this.onTap});
  final _NavItem item;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : AppColors.sidebarText;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: active ? AppColors.sidebarHover : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          hoverColor: AppColors.sidebarHover,
          onTap: onTap ??
              () {
                if (Scaffold.maybeOf(context)?.isDrawerOpen ?? false) Navigator.pop(context);
                Navigator.pushReplacementNamed(context, item.route, arguments: Session.routeArgs);
              },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, required this.showMenu});
  final String title;
  final bool showMenu;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 64,
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
          if (showMenu) const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(title, style: theme.textTheme.titleLarge, overflow: TextOverflow.ellipsis),
          ),
          _UserMenu(),
        ],
      ),
    );
  }
}

class _UserMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return PopupMenuButton<String>(
      tooltip: 'Mon compte',
      offset: const Offset(0, 52),
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
        const PopupMenuItem(value: 'profil', child: ListTile(leading: Icon(Icons.person_outline_rounded), title: Text('Mon profil'), dense: true, contentPadding: EdgeInsets.zero)),
        const PopupMenuItem(value: 'password', child: ListTile(leading: Icon(Icons.lock_outline_rounded), title: Text('Mot de passe'), dense: true, contentPadding: EdgeInsets.zero)),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'logout', child: ListTile(leading: Icon(Icons.logout_rounded, color: AppColors.danger), title: Text('Déconnexion', style: TextStyle(color: AppColors.danger)), dense: true, contentPadding: EdgeInsets.zero)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InitialsAvatar(name: Session.fullName, size: 34),
            if (wide) ...[
              const SizedBox(width: 10),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Session.fullName.isEmpty ? 'Mon compte' : Session.fullName, style: t.titleSmall),
                  Text(Session.roleLabel, style: t.bodySmall),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.expand_more_rounded, size: 18, color: t.bodySmall?.color),
            ],
          ],
        ),
      ),
    );
  }
}

/// Logo FasoCarbu : pictogramme + nom.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false, this.size = 34});
  final bool onDark;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.brand,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.local_gas_station_rounded, color: Colors.white, size: size * 0.58),
        ),
        SizedBox(width: size * 0.32),
        Text(
          'FasoCarbu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: size * 0.56,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                color: onDark ? Colors.white : null,
              ),
        ),
      ],
    );
  }
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
