import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/demande.dart';
import '../services/DashboardService.dart';
import '../services/demande_service.dart';
import '../services/push_notification_service.dart';
import 'main_layout.dart';

class DashboardGestionnaireScreen extends StatefulWidget {
  const DashboardGestionnaireScreen({super.key});

  @override
  State<DashboardGestionnaireScreen> createState() => _DashboardGestionnaireScreenState();
}

class _DashboardGestionnaireScreenState extends State<DashboardGestionnaireScreen> {
  final _dashboard = DashboardService(baseUrl: AppConfig.backendUrl);
  final _demandes = DemandeService();

  bool _loading = true;
  String? _error;
  int _userCount = 0;
  int _stationCount = 0;
  int _vehiculeCount = 0;
  List<Demande> _allDemandes = [];

  @override
  void initState() {
    super.initState();
    _load();
    _setupPushNotifications();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = Session.token;
    try {
      final results = await Future.wait([
        _dashboard.getUserCount(token),
        _dashboard.getStationCount(token),
        _dashboard.getVehiculeCount(token),
      ]);
      List<Demande> demandes = [];
      try {
        demandes = await _demandes.getAllDemandes(jwtToken: token);
      } catch (_) {
        // Les demandes sont un complément : on n'empêche pas l'affichage.
      }
      if (!mounted) return;
      setState(() {
        _userCount = results[0];
        _stationCount = results[1];
        _vehiculeCount = results[2];
        _allDemandes = demandes..sort((a, b) => b.id.compareTo(a.id));
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossible de charger le tableau de bord.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setupPushNotifications() async {
    try {
      final push = PushNotificationService();
      final fcmToken = await push.getTokenSafe();
      if (fcmToken != null && Session.userId.isNotEmpty) {
        await push.sendTokenToBackend(fcmToken: fcmToken, userId: Session.userId, jwtToken: Session.token);
      }
      FirebaseMessaging.onMessage.listen((message) {
        final n = message.notification;
        if (n == null || !mounted) return;
        showAppSnack(context, '${n.title ?? ''} — ${n.body ?? ''}', tone: Tone.info);
        _load();
      });
    } catch (e) {
      debugPrint('Notifications push indisponibles : $e');
    }
  }

  int _count(String statut) => _allDemandes.where((d) => d.statut.toUpperCase() == statut).length;

  void _go(String route) => Navigator.pushReplacementNamed(context, route, arguments: Session.routeArgs);

  String get _greeting {
    final h = DateTime.now().hour;
    return h < 12 ? 'Bonjour' : (h < 18 ? 'Bon après-midi' : 'Bonsoir');
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Tableau de bord',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: '$_greeting${Session.prenom.isNotEmpty ? ', ${Session.prenom}' : ''}',
            subtitle: 'Voici l\'activité carburant de votre entreprise.',
            actions: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Actualiser'),
              ),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/demandes/form', arguments: Session.routeArgs)
                    .then((_) => _load()),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle demande'),
              ),
            ],
          ),
          if (_error != null)
            Card(child: ErrorState(message: _error!, onRetry: _load))
          else if (_loading)
            const LoadingView(message: 'Chargement des indicateurs…')
          else ...[
            ResponsiveGrid(children: [
              StatCard(
                label: 'Demandes en attente',
                value: '${_count('EN_ATTENTE')}',
                icon: Icons.pending_actions_rounded,
                tone: Tone.warning,
                hint: '${_allDemandes.length} demande${_allDemandes.length > 1 ? 's' : ''} au total',
                onTap: () => _go('/demandes'),
              ),
              StatCard(
                label: 'Utilisateurs',
                value: '$_userCount',
                icon: Icons.group_rounded,
                tone: Tone.info,
                onTap: () => _go('/users'),
              ),
              StatCard(
                label: 'Stations partenaires',
                value: '$_stationCount',
                icon: Icons.local_gas_station_rounded,
                tone: Tone.brand,
                onTap: () => _go('/stations'),
              ),
              StatCard(
                label: 'Véhicules',
                value: '$_vehiculeCount',
                icon: Icons.directions_car_rounded,
                tone: Tone.success,
                onTap: () => _go('/vehicules'),
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            LayoutBuilder(builder: (context, c) {
              final recent = _RecentDemandes(demandes: _allDemandes.take(6).toList(), onSeeAll: () => _go('/demandes'));
              final breakdown = _DemandeBreakdown(
                enAttente: _count('EN_ATTENTE'),
                validees: _count('VALIDEE'),
                rejetees: _count('REJETEE'),
              );
              if (c.maxWidth < 900) {
                return Column(children: [recent, const SizedBox(height: AppSpacing.lg), breakdown]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: recent),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: breakdown),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _RecentDemandes extends StatelessWidget {
  const _RecentDemandes({required this.demandes, required this.onSeeAll});
  final List<Demande> demandes;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      title: 'Demandes récentes',
      subtitle: 'Les dernières demandes de carburant',
      trailing: TextButton(onPressed: onSeeAll, child: const Text('Tout voir')),
      padding: EdgeInsets.zero,
      child: demandes.isEmpty
          ? const EmptyState(
              icon: Icons.assignment_outlined,
              title: 'Aucune demande',
              message: 'Les demandes de vos équipes apparaîtront ici.',
            )
          : Column(
              children: [
                for (var i = 0; i < demandes.length; i++) ...[
                  if (i > 0) const Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                    child: Row(
                      children: [
                        InitialsAvatar(
                          name: '${demandes[i].demandeurPrenom ?? ''} ${demandes[i].demandeurNom ?? ''}',
                          size: 34,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${formatNumber(demandes[i].quantite)} L · ${demandes[i].carburantNom}',
                                style: t.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  '${demandes[i].demandeurPrenom ?? ''} ${demandes[i].demandeurNom ?? ''}'.trim(),
                                  demandes[i].vehiculeImmatriculation,
                                  demandes[i].stationNom,
                                ].where((s) => s.isNotEmpty).join(' · '),
                                style: t.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        StatusBadge.fromStatus(demandes[i].statut),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

class _DemandeBreakdown extends StatelessWidget {
  const _DemandeBreakdown({required this.enAttente, required this.validees, required this.rejetees});
  final int enAttente;
  final int validees;
  final int rejetees;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = enAttente + validees + rejetees;

    Widget row(String label, int value, Tone tone) {
      final ratio = total == 0 ? 0.0 : value / total;
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Text(label, style: t.bodyMedium)),
              Text('$value', style: t.titleSmall),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                color: tone.fg,
                backgroundColor: tone.softBg(context),
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      title: 'Répartition des demandes',
      subtitle: total == 0 ? 'Aucune donnée' : '$total demande${total > 1 ? 's' : ''}',
      child: Column(children: [
        row('En attente', enAttente, Tone.warning),
        row('Validées', validees, Tone.success),
        row('Rejetées', rejetees, Tone.danger),
      ]),
    );
  }
}
