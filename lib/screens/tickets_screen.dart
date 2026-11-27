import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/ticket_card.dart';
import '../models/ticket.dart';
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/ticket_service.dart';
import 'main_layout.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _service = TicketService();
  List<Ticket> _tickets = [];
  bool _loading = true;
  String? _error;
  String _filter = 'TOUS';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.getTickets();
      list.sort((a, b) => (b.dateEmission ?? DateTime(0)).compareTo(a.dateEmission ?? DateTime(0)));
      if (mounted) setState(() => _tickets = list);
    } catch (e) {
      if (mounted) setState(() => _error = 'Impossible de charger les tickets.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _beneficiaire(Ticket t) => '${t.utilisateurPrenom ?? ''} ${t.utilisateurNom ?? ''}'.trim();

  List<Ticket> get _visible {
    final q = _search.toLowerCase();
    return _tickets.where((t) {
      if (_filter != 'TOUS' && statusInfo(t.statut).label != statusInfo(_filter).label) return false;
      if (q.isEmpty) return true;
      return [_beneficiaire(t), t.stationNom ?? '', t.vehiculeImmatriculation ?? '', t.carburantNom ?? '', '#${t.id}']
          .any((s) => s.toLowerCase().contains(q));
    }).toList();
  }

  Future<void> _attribuer(Ticket t) async {
    if (t.entrepriseId == null || t.id == null) {
      showAppSnack(context, 'Entreprise du ticket introuvable.', tone: Tone.danger);
      return;
    }
    List<User> chauffeurs;
    try {
      chauffeurs = await context.read<UserProvider>().loadChauffeursByEntreprise(t.entrepriseId.toString());
    } catch (_) {
      if (mounted) showAppSnack(context, 'Liste des chauffeurs indisponible.', tone: Tone.danger);
      return;
    }
    if (!mounted) return;
    if (chauffeurs.isEmpty) {
      showAppSnack(context, 'Aucun chauffeur disponible dans l\'entreprise.', tone: Tone.warning);
      return;
    }
    final chauffeur = await showDialog<User>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Attribuer le ticket #${t.id}'),
        content: SizedBox(
          width: 400,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final c in chauffeurs)
                ListTile(
                  leading: InitialsAvatar(name: '${c.prenom} ${c.nom}', size: 32),
                  title: Text('${c.prenom} ${c.nom}'),
                  subtitle: Text(c.telephone.isEmpty ? c.email : c.telephone),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  onTap: () => Navigator.pop(ctx, c),
                ),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler'))],
      ),
    );
    if (chauffeur == null) return;
    try {
      await _service.attribuerTicket(t.id!, chauffeur.id!);
      if (!mounted) return;
      showAppSnack(context, 'Ticket attribué à ${chauffeur.prenom} ${chauffeur.nom}.', tone: Tone.success);
      _load();
    } catch (e) {
      if (mounted) showAppSnack(context, 'Attribution impossible.', tone: Tone.danger);
    }
  }

  void _showQr(Ticket t) {
    final data = TicketData(
      id: t.id?.toString(),
      statut: t.statut,
      quantite: t.quantite,
      montant: t.somme ?? t.montant,
      carburant: t.carburantNom,
      station: t.stationNom,
      vehicule: t.vehiculeImmatriculation,
      beneficiaire: _beneficiaire(t),
      entreprise: t.entrepriseNom,
      validateur: '${t.validateurPrenom ?? ''} ${t.validateurNom ?? ''}'.trim(),
      dateEmission: t.dateEmission,
      dateValidation: t.dateValidation,
      codeQr: t.codeQr,
    );
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(height: AppSpacing.sm),
                TicketCard(data: data),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _tickets.fold<double>(0, (s, t) => s + (t.somme ?? t.montant ?? 0));
    final litres = _tickets.fold<double>(0, (s, t) => s + (t.quantite ?? 0));
    int count(String s) => _tickets.where((t) => statusInfo(t.statut).label == statusInfo(s).label).length;
    final visible = _visible;
    final isGestionnaire = Session.role.toUpperCase().contains('GESTIONNAIRE');

    return MainLayout(
      title: 'Tickets',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Pilotage',
            icon: Icons.confirmation_number_rounded,
            title: 'Tickets carburant',
            subtitle: 'Tickets émis après validation des demandes, avec leur QR code.',
            actions: [
              OutlinedButton.icon(
                onPressed: _loading ? null : _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Actualiser'),
              ),
            ],
          ),
          if (!_loading && _error == null) ...[
            ResponsiveGrid(minItemWidth: 220, children: [
              StatCard(label: 'Tickets émis', value: '${_tickets.length}', icon: Icons.confirmation_number_rounded),
              StatCard(label: 'En attente', value: '${count('EN_ATTENTE')}', icon: Icons.schedule_rounded, tone: Tone.warning),
              StatCard(label: 'Volume', value: '${formatNumber(litres)} L', icon: Icons.water_drop_rounded, tone: Tone.info),
              StatCard(label: 'Montant total', value: formatNumber(total), hint: 'FCFA', icon: Icons.payments_rounded, tone: Tone.success),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilterPills<String>(
                options: [
                  ('TOUS', 'Tous', _tickets.length),
                  ('EN_ATTENTE', 'En attente', count('EN_ATTENTE')),
                  ('VALIDER', 'Validés', count('VALIDER')),
                  ('CONSOMMEE', 'Consommés', count('CONSOMMEE')),
                  ('REJETER', 'Rejetés', count('REJETER')),
                ],
                selected: _filter,
                onChanged: (v) => setState(() => _filter = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              SearchField(hint: 'Bénéficiaire, station…', onChanged: (v) => setState(() => _search = v)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : visible.isEmpty
                        ? EmptyState(
                            icon: Icons.confirmation_number_outlined,
                            title: _tickets.isEmpty ? 'Aucun ticket' : 'Aucun résultat',
                            message: _tickets.isEmpty
                                ? 'Les tickets apparaissent ici dès qu\'une demande est validée.'
                                : 'Modifiez les filtres ou la recherche.',
                          )
                        : AppDataTable(
                            columns: const [
                              DataColumn(label: Text('N°')),
                              DataColumn(label: Text('ÉMIS LE')),
                              DataColumn(label: Text('BÉNÉFICIAIRE')),
                              DataColumn(label: Text('CARBURANT')),
                              DataColumn(label: Text('MONTANT'), numeric: true),
                              DataColumn(label: Text('STATION')),
                              DataColumn(label: Text('STATUT')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final t in visible)
                                DataRow(cells: [
                                  DataCell(Text('#${t.id ?? '—'}', style: Theme.of(context).textTheme.bodySmall)),
                                  DataCell(Text(formatDate(t.dateEmission, withTime: true))),
                                  DataCell(Text(_beneficiaire(t).isEmpty ? '—' : _beneficiaire(t))),
                                  DataCell(Text('${formatNumber(t.quantite)} L · ${t.carburantNom ?? '—'}')),
                                  DataCell(Text('${formatNumber(t.somme ?? t.montant)} FCFA')),
                                  DataCell(Text(t.stationNom ?? '—')),
                                  DataCell(StatusBadge.fromStatus(t.statut)),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (t.codeQr != null && t.codeQr!.isNotEmpty)
                                      IconButton(
                                        tooltip: 'Voir le QR code',
                                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                                        onPressed: () => _showQr(t),
                                      ),
                                    if (isGestionnaire)
                                      IconButton(
                                        tooltip: 'Attribuer à un chauffeur',
                                        icon: const Icon(Icons.person_add_alt_outlined, size: 20),
                                        onPressed: () => _attribuer(t),
                                      ),
                                  ])),
                                ]),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
