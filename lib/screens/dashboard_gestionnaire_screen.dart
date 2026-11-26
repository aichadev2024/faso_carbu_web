import 'dart:math' as math;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/logo.dart';
import '../models/demande.dart';
import '../models/ticket.dart';
import '../services/DashboardService.dart';
import '../services/demande_service.dart';
import '../services/push_notification_service.dart';
import '../services/ticket_service.dart';
import 'main_layout.dart';

class DashboardGestionnaireScreen extends StatefulWidget {
  const DashboardGestionnaireScreen({super.key});

  @override
  State<DashboardGestionnaireScreen> createState() => _DashboardGestionnaireScreenState();
}

class _DashboardGestionnaireScreenState extends State<DashboardGestionnaireScreen> {
  final _dashboard = DashboardService(baseUrl: AppConfig.backendUrl);
  final _demandes = DemandeService();
  final _ticketService = TicketService();

  bool _loading = true;
  String? _error;
  int _userCount = 0;
  int _stationCount = 0;
  int _vehiculeCount = 0;
  List<Demande> _allDemandes = [];
  List<Ticket> _tickets = [];

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
      // Demandes et tickets complètent les indicateurs : un échec ne bloque pas la page.
      List<Demande> demandes = [];
      List<Ticket> tickets = [];
      try {
        demandes = await _demandes.getAllDemandes(jwtToken: token);
      } catch (_) {}
      try {
        tickets = await _ticketService.getTickets();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _userCount = results[0];
        _stationCount = results[1];
        _vehiculeCount = results[2];
        _allDemandes = demandes..sort((a, b) => b.id.compareTo(a.id));
        _tickets = tickets;
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

  bool _thisMonth(DateTime? d) {
    final n = DateTime.now();
    return d != null && d.year == n.year && d.month == n.month;
  }

  @override
  Widget build(BuildContext context) {
    final enAttente = _count('EN_ATTENTE');
    final duMois = _tickets.where((t) => _thisMonth(t.dateEmission)).toList();
    final volumeMois = duMois.fold<double>(0, (s, t) => s + (t.quantite ?? 0));
    final depenseMois = duMois.fold<double>(0, (s, t) => s + (t.somme ?? t.montant ?? 0));
    final ticketsActifs = _tickets.where((t) => (t.statut ?? '').toUpperCase() == 'EN_ATTENTE').length;

    return MainLayout(
      title: 'Tableau de bord',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeroBanner(
            greeting: '$_greeting${Session.prenom.isNotEmpty ? ', ${Session.prenom}' : ''}',
            enAttente: enAttente,
            loading: _loading,
            onValider: () => _go('/demandes'),
            onNouvelle: () => Navigator.pushNamed(context, '/demandes/form', arguments: Session.routeArgs).then((_) => _load()),
            onRefresh: _loading ? null : _load,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_error != null)
            Card(child: ErrorState(message: _error!, onRetry: _load))
          else if (_loading)
            const LoadingView(message: 'Chargement des indicateurs…')
          else ...[
            ResponsiveGrid(children: [
              StatCard(
                label: 'Demandes à traiter',
                value: '$enAttente',
                icon: Icons.pending_actions_rounded,
                tone: Tone.warning,
                hint: '${_allDemandes.length} demande${_allDemandes.length > 1 ? 's' : ''} au total',
                onTap: () => _go('/demandes'),
              ),
              StatCard(
                label: 'Volume ce mois',
                value: '${formatNumber(volumeMois)} L',
                icon: Icons.water_drop_rounded,
                tone: Tone.info,
                hint: '${duMois.length} ticket${duMois.length > 1 ? 's' : ''} émis',
                onTap: () => _go('/tickets'),
              ),
              StatCard(
                label: 'Dépenses ce mois',
                value: formatNumber(depenseMois),
                icon: Icons.payments_rounded,
                tone: Tone.success,
                hint: 'FCFA · $ticketsActifs ticket${ticketsActifs > 1 ? 's' : ''} actif${ticketsActifs > 1 ? 's' : ''}',
                onTap: () => _go('/rapports'),
              ),
              StatCard(
                label: 'Flotte',
                value: '$_vehiculeCount véhicule${_vehiculeCount > 1 ? 's' : ''}',
                icon: Icons.local_shipping_rounded,
                tone: Tone.brand,
                hint: '$_stationCount station${_stationCount > 1 ? 's' : ''} · $_userCount utilisateur${_userCount > 1 ? 's' : ''}',
                onTap: () => _go('/vehicules'),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(builder: (context, c) {
              final chart = _VolumeChart(tickets: _tickets);
              final breakdown = _DemandeBreakdown(
                enAttente: enAttente,
                validees: _count('VALIDEE'),
                rejetees: _count('REJETEE'),
              );
              if (c.maxWidth < 900) {
                return Column(children: [chart, const SizedBox(height: AppSpacing.lg), breakdown]);
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 2, child: chart),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: breakdown),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            _RecentDemandes(demandes: _allDemandes.take(6).toList(), onSeeAll: () => _go('/demandes')),
          ],
        ],
      ),
    );
  }
}

/// Bandeau d'accueil : salutation, demandes à traiter, actions principales.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({
    required this.greeting,
    required this.enAttente,
    required this.loading,
    required this.onValider,
    required this.onNouvelle,
    required this.onRefresh,
  });

  final String greeting;
  final int enAttente;
  final bool loading;
  final VoidCallback onValider;
  final VoidCallback onNouvelle;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final message = loading
        ? 'Chargement de l\'activité…'
        : enAttente == 0
            ? 'Aucune demande en attente : tout est à jour.'
            : '$enAttente demande${enAttente > 1 ? 's' : ''} de carburant attend${enAttente > 1 ? 'ent' : ''} votre validation.';
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: inkGradient,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.soft(context),
      ),
      child: Stack(
        children: [
          // Halo orange et logo en filigrane.
          Positioned(
            right: -60,
            top: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.brand.withValues(alpha: 0.45), AppColors.brand.withValues(alpha: 0)]),
              ),
            ),
          ),
          const Positioned(
            right: 36,
            bottom: -26,
            child: Opacity(opacity: 0.10, child: LogoMark(size: 170, withBackground: false, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 30, 32, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Text(
                    'ESPACE GESTIONNAIRE',
                    style: t.labelSmall?.copyWith(color: const Color(0xFFFDBA74), letterSpacing: 1.4),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(greeting, style: t.headlineMedium?.copyWith(color: Colors.white, fontSize: 30)),
                const SizedBox(height: 6),
                Text(message, style: t.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.72))),
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      onPressed: onNouvelle,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouvelle demande'),
                      style: FilledButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
                    ),
                    if (enAttente > 0)
                      FilledButton.icon(
                        onPressed: onValider,
                        icon: const Icon(Icons.task_alt_rounded, size: 18),
                        label: const Text('Traiter les demandes'),
                        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.textPrimary),
                      ),
                    OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Actualiser'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.45),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Volume de carburant des tickets émis sur les 14 derniers jours.
class _VolumeChart extends StatelessWidget {
  const _VolumeChart({required this.tickets});
  final List<Ticket> tickets;

  static const _jours = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = theme.textTheme;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 13));
    final days = [for (var i = 0; i < 14; i++) start.add(Duration(days: i))];
    final volumes = [
      for (final d in days)
        tickets
            .where((tk) {
              final e = tk.dateEmission;
              return e != null && e.year == d.year && e.month == d.month && e.day == d.day;
            })
            .fold<double>(0, (s, tk) => s + (tk.quantite ?? 0)),
    ];
    final total = volumes.fold<double>(0, (a, b) => a + b);
    final maxY = math.max(10.0, volumes.fold<double>(0, math.max) * 1.25);

    return AppCard(
      title: 'Volume distribué',
      subtitle: '14 derniers jours · ${formatNumber(total)} L',
      trailing: const StatusBadge(label: 'Tickets émis', tone: Tone.info),
      child: SizedBox(
        height: 240,
        child: Stack(
          children: [
            BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(color: theme.dividerColor, strokeWidth: 1, dashArray: [4, 4]),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: maxY / 4,
                      getTitlesWidget: (v, meta) => Text('${formatNumber(v)} L', style: t.bodySmall?.copyWith(fontSize: 11)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (v, meta) {
                        final d = days[v.toInt()];
                        final isToday = v.toInt() == days.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(children: [
                            Text(_jours[d.weekday - 1], style: t.bodySmall?.copyWith(fontSize: 10.5)),
                            Text(
                              '${d.day}',
                              style: t.labelMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                                color: isToday ? theme.colorScheme.primary : null,
                              ),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                      '${formatDate(days[group.x])}\n${formatNumber(rod.toY)} L',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < volumes.length; i++)
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: volumes[i],
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFFEA580C), Color(0xFFFBBF24)],
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6),
                        ),
                      ),
                    ]),
                ],
              ),
            ),
            if (total == 0)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text('Aucun ticket émis sur la période', style: t.bodySmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Répartition des demandes par statut, en anneau.
class _DemandeBreakdown extends StatelessWidget {
  const _DemandeBreakdown({required this.enAttente, required this.validees, required this.rejetees});
  final int enAttente;
  final int validees;
  final int rejetees;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = enAttente + validees + rejetees;
    final parts = [
      ('En attente', enAttente, AppColors.warning),
      ('Validées', validees, AppColors.success),
      ('Rejetées', rejetees, AppColors.danger),
    ];

    return AppCard(
      title: 'Demandes',
      subtitle: 'Répartition par statut',
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: total == 0 ? 0 : 3,
                    centerSpaceRadius: 50,
                    startDegreeOffset: -90,
                    sections: total == 0
                        ? [PieChartSectionData(value: 1, color: Theme.of(context).colorScheme.surfaceContainerHigh, radius: 16, showTitle: false)]
                        : [
                            for (final p in parts)
                              if (p.$2 > 0) PieChartSectionData(value: p.$2.toDouble(), color: p.$3, radius: 16, showTitle: false),
                          ],
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('$total', style: t.headlineMedium),
                  Text('au total', style: t.bodySmall),
                ]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final p in parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Container(width: 10, height: 10, decoration: BoxDecoration(color: p.$3, borderRadius: BorderRadius.circular(3))),
                const SizedBox(width: 10),
                Expanded(child: Text(p.$1, style: t.bodyMedium)),
                Text('${p.$2}', style: t.titleSmall),
                SizedBox(
                  width: 48,
                  child: Text(
                    total == 0 ? '—' : '${(p.$2 * 100 / total).round()} %',
                    style: t.bodySmall,
                    textAlign: TextAlign.right,
                  ),
                ),
              ]),
            ),
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
      subtitle: 'Les dernières demandes de carburant de vos équipes',
      trailing: TextButton.icon(
        onPressed: onSeeAll,
        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
        label: const Text('Tout voir'),
      ),
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
                  if (i > 0) const Divider(indent: AppSpacing.xl, endIndent: AppSpacing.xl),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 14),
                    child: Row(
                      children: [
                        InitialsAvatar(
                          name: '${demandes[i].demandeurPrenom ?? ''} ${demandes[i].demandeurNom ?? ''}',
                          size: 38,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${demandes[i].demandeurPrenom ?? ''} ${demandes[i].demandeurNom ?? ''}'.trim().isEmpty
                                    ? 'Demande #${demandes[i].id}'
                                    : '${demandes[i].demandeurPrenom ?? ''} ${demandes[i].demandeurNom ?? ''}'.trim(),
                                style: t.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [demandes[i].vehiculeImmatriculation, demandes[i].stationNom].where((s) => s.isNotEmpty).join(' · '),
                                style: t.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${formatNumber(demandes[i].quantite)} L', style: t.titleSmall),
                            Text(demandes[i].carburantNom, style: t.bodySmall),
                          ],
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        SizedBox(width: 104, child: Align(alignment: Alignment.centerRight, child: StatusBadge.fromStatus(demandes[i].statut))),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
