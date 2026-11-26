import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/logo.dart';
import '../core/theme/app_colors.dart';
import '../models/station.dart';
import '../providers/station_provider.dart';
import 'main_layout.dart';
import 'station_form_screen.dart';

class StationListScreen extends StatefulWidget {
  const StationListScreen({super.key, required this.jwtToken});
  final String jwtToken;

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  String _search = '';
  String? _error;

  String get _token => widget.jwtToken.isNotEmpty ? widget.jwtToken : Session.token;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<StationProvider>().loadStations(jwtToken: _token);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les stations.');
    }
  }

  Future<void> _create() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/stations/form'),
        builder: (_) => StationFormScreen(jwtToken: _token),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _delete(Station s) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer « ${s.nom} » ?',
      message: 'La station et ses carburants ne seront plus proposés dans les demandes.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<StationProvider>().removeStation(s.id, jwtToken: _token);
      if (mounted) showAppSnack(context, 'Station supprimée.', tone: Tone.success);
    } catch (_) {
      if (mounted) showAppSnack(context, 'La suppression a échoué.', tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StationProvider>();
    final q = _search.toLowerCase();
    final stations = provider.stations
        .where((s) => '${s.nom} ${s.ville} ${s.adresse}'.toLowerCase().contains(q))
        .toList();
    final actives = provider.stations.where((s) => s.actif).length;

    return MainLayout(
      title: 'Stations',
      jwtToken: _token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Gestion',
            icon: Icons.local_gas_station_rounded,
            title: 'Stations partenaires',
            subtitle: provider.stations.isEmpty
                ? 'Les stations où vos chauffeurs peuvent utiliser leurs tickets.'
                : '${provider.stations.length} stations · $actives actives',
            actions: [
              FilledButton.icon(
                onPressed: _create,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Nouvelle station'),
              ),
            ],
          ),
          SearchField(hint: 'Nom, ville, adresse…', onChanged: (v) => setState(() => _search = v)),
          const SizedBox(height: AppSpacing.lg),
          if (provider.loading && provider.stations.isEmpty)
            const LoadingView()
          else if (_error != null)
            Card(child: ErrorState(message: _error!, onRetry: _load))
          else if (stations.isEmpty)
            Card(
              child: EmptyState(
                icon: Icons.local_gas_station_outlined,
                title: provider.stations.isEmpty ? 'Aucune station' : 'Aucun résultat',
                message: provider.stations.isEmpty
                    ? 'Ajoutez une station et son administrateur pour commencer.'
                    : 'Modifiez votre recherche.',
                action: provider.stations.isEmpty
                    ? FilledButton(onPressed: _create, child: const Text('Nouvelle station'))
                    : null,
              ),
            )
          else
            ResponsiveGrid(
              minItemWidth: 300,
              maxColumns: 3,
              children: [for (final s in stations) _StationCard(station: s, onDelete: () => _delete(s))],
            ),
        ],
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  const _StationCard({required this.station, required this.onDelete});
  final Station station;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau de la carte : pictogramme, statut et actions.
          Container(
            height: 76,
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            decoration: const BoxDecoration(gradient: inkGradient),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Positioned(
                  right: 40,
                  bottom: -22,
                  child: Opacity(opacity: 0.10, child: LogoMark(size: 80, withBackground: false, color: Colors.white)),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(gradient: brandGradient, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: const Icon(Icons.local_gas_station_rounded, size: 21, color: Colors.white),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: (station.actif ? AppColors.success : AppColors.textMutedDark).withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        station.actif ? 'Active' : 'Inactive',
                        style: t.labelMedium?.copyWith(
                          color: station.actif ? const Color(0xFF86EFAC) : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Actions',
                      icon: const Icon(Icons.more_vert_rounded, size: 20, color: Colors.white70),
                      onSelected: (v) => v == 'delete' ? onDelete() : null,
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Supprimer', style: TextStyle(color: Tone.danger.fg)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(station.nom, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.place_outlined, size: 16, color: t.bodySmall?.color),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      station.adresse.isEmpty ? 'Adresse non renseignée' : station.adresse,
                      style: t.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
                if (station.ville.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  StatusBadge(label: station.ville, tone: Tone.brand),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
