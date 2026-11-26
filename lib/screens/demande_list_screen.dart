import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/demande.dart';
import '../providers/demande_provider.dart';
import 'main_layout.dart';

class DemandeListScreen extends StatefulWidget {
  const DemandeListScreen({super.key});

  @override
  State<DemandeListScreen> createState() => _DemandeListScreenState();
}

class _DemandeListScreenState extends State<DemandeListScreen> {
  String _filter = 'TOUTES';
  String _search = '';
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() => context.read<DemandeProvider>().fetchDemandes(Session.token);

  String _nom(Demande d) {
    final demandeur = '${d.demandeurPrenom ?? ''} ${d.demandeurNom ?? ''}'.trim();
    if (demandeur.isNotEmpty) return demandeur;
    return '${d.gestionnairePrenom ?? ''} ${d.gestionnaireNom ?? ''}'.trim();
  }

  List<Demande> _visible(List<Demande> all) {
    final q = _search.toLowerCase();
    return all.where((d) {
      if (_filter != 'TOUTES' && d.statut.toUpperCase() != _filter) return false;
      if (q.isEmpty) return true;
      return [_nom(d), d.carburantNom, d.stationNom, d.vehiculeImmatriculation, '#${d.id}']
          .any((s) => s.toLowerCase().contains(q));
    }).toList()
      ..sort((a, b) => b.id.compareTo(a.id));
  }

  Future<void> _validate(Demande d) async {
    final ok = await confirmDialog(
      context,
      title: 'Valider la demande #${d.id} ?',
      message: '${formatNumber(d.quantite)} L de ${d.carburantNom} pour ${_nom(d)}. '
          'Un ticket QR sera généré pour le chauffeur.',
      confirmLabel: 'Valider',
    );
    if (!ok || !mounted) return;
    setState(() => _busy.add(d.id));
    final provider = context.read<DemandeProvider>();
    await provider.validateDemande(d.id, Session.token);
    if (!mounted) return;
    setState(() => _busy.remove(d.id));
    showAppSnack(
      context,
      provider.errorMessage == null ? 'Demande #${d.id} validée.' : 'Échec de la validation.',
      tone: provider.errorMessage == null ? Tone.success : Tone.danger,
    );
  }

  Future<void> _reject(Demande d) async {
    final motif = await showDialog<String>(context: context, builder: (_) => _RejectDialog(demande: d));
    if (motif == null || !mounted) return;
    setState(() => _busy.add(d.id));
    final provider = context.read<DemandeProvider>();
    await provider.rejectDemande(d.id, Session.token, motif: motif);
    if (!mounted) return;
    setState(() => _busy.remove(d.id));
    showAppSnack(
      context,
      provider.errorMessage == null ? 'Demande #${d.id} rejetée.' : 'Échec du rejet.',
      tone: provider.errorMessage == null ? Tone.neutral : Tone.danger,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Demandes',
      jwtToken: Session.token,
      child: Consumer<DemandeProvider>(builder: (context, provider, _) {
        final all = provider.demandes;
        int count(String s) => all.where((d) => d.statut.toUpperCase() == s).length;
        final visible = _visible(all);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              eyebrow: 'Pilotage',
              icon: Icons.assignment_rounded,
              title: 'Demandes de carburant',
              subtitle: 'Validez ou rejetez les demandes de vos équipes.',
              actions: [
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/demandes/form', arguments: Session.routeArgs)
                      .then((_) => _load()),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nouvelle demande'),
                ),
              ],
            ),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilterPills<String>(
                  options: [
                    ('TOUTES', 'Toutes', all.length),
                    ('EN_ATTENTE', 'En attente', count('EN_ATTENTE')),
                    ('VALIDEE', 'Validées', count('VALIDEE')),
                    ('REJETEE', 'Rejetées', count('REJETEE')),
                  ],
                  selected: _filter,
                  onChanged: (v) => setState(() => _filter = v),
                ),
                const SizedBox(width: AppSpacing.sm),
                SearchField(
                  hint: 'Demandeur, station, véhicule…',
                  onChanged: (v) => setState(() => _search = v),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              clipBehavior: Clip.antiAlias,
              child: provider.isLoading
                  ? const LoadingView()
                  : provider.errorMessage != null && all.isEmpty
                      ? ErrorState(message: 'Impossible de charger les demandes.', onRetry: _load)
                      : visible.isEmpty
                          ? EmptyState(
                              icon: Icons.assignment_outlined,
                              title: all.isEmpty ? 'Aucune demande' : 'Aucun résultat',
                              message: all.isEmpty
                                  ? 'Créez une demande ou attendez celles de vos équipes.'
                                  : 'Modifiez les filtres ou la recherche.',
                            )
                          : AppDataTable(
                              columns: const [
                                DataColumn(label: Text('N°')),
                                DataColumn(label: Text('DEMANDEUR')),
                                DataColumn(label: Text('CARBURANT')),
                                DataColumn(label: Text('QUANTITÉ'), numeric: true),
                                DataColumn(label: Text('VÉHICULE')),
                                DataColumn(label: Text('STATION')),
                                DataColumn(label: Text('STATUT')),
                                DataColumn(label: Text('')),
                              ],
                              rows: [
                                for (final d in visible)
                                  DataRow(cells: [
                                    DataCell(Text('#${d.id}', style: Theme.of(context).textTheme.bodySmall)),
                                    DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                      InitialsAvatar(name: _nom(d), size: 28),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(_nom(d).isEmpty ? '—' : _nom(d)),
                                    ])),
                                    DataCell(Text(d.carburantNom.isEmpty ? '—' : d.carburantNom)),
                                    DataCell(Text('${formatNumber(d.quantite)} L')),
                                    DataCell(Text(d.vehiculeImmatriculation.isEmpty ? '—' : d.vehiculeImmatriculation)),
                                    DataCell(Text(d.stationNom.isEmpty ? '—' : d.stationNom)),
                                    DataCell(StatusBadge.fromStatus(d.statut)),
                                    DataCell(_actions(d)),
                                  ]),
                              ],
                            ),
            ),
          ],
        );
      }),
    );
  }

  Widget _actions(Demande d) {
    if (d.statut.toUpperCase() != 'EN_ATTENTE') return const SizedBox.shrink();
    if (_busy.contains(d.id)) {
      return const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      TextButton(
        onPressed: () => _reject(d),
        style: TextButton.styleFrom(foregroundColor: Tone.danger.fg),
        child: const Text('Rejeter'),
      ),
      const SizedBox(width: AppSpacing.xs),
      FilledButton(
        onPressed: () => _validate(d),
        style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10)),
        child: const Text('Valider'),
      ),
    ]);
  }
}

class _RejectDialog extends StatefulWidget {
  const _RejectDialog({required this.demande});
  final Demande demande;

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Rejeter la demande #${widget.demande.id}'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Le demandeur sera notifié avec ce motif.'),
            const SizedBox(height: AppSpacing.lg),
            const FieldLabel('Motif du rejet', required: true),
            TextField(
              controller: _ctrl,
              autofocus: true,
              maxLines: 3,
              decoration: InputDecoration(hintText: 'Ex. quota mensuel atteint', errorText: _error),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Tone.danger.fg),
          onPressed: () {
            final m = _ctrl.text.trim();
            if (m.isEmpty) {
              setState(() => _error = 'Indiquez un motif');
              return;
            }
            Navigator.pop(context, m);
          },
          child: const Text('Rejeter'),
        ),
      ],
    );
  }
}
