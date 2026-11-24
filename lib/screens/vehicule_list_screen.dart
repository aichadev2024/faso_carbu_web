import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../dtos/vehicule_request.dart';
import '../models/vehicule.dart';
import '../providers/vehicule_provider.dart';
import 'main_layout.dart';
import 'vehicule_form_screen.dart';

class VehiculeListScreen extends StatefulWidget {
  const VehiculeListScreen({super.key, required this.jwtToken});
  final String jwtToken;

  @override
  State<VehiculeListScreen> createState() => _VehiculeListScreenState();
}

class _VehiculeListScreenState extends State<VehiculeListScreen> {
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
      await context.read<VehiculeProvider>().loadVehicules(jwtToken: _token);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les véhicules.');
    }
  }

  Future<void> _openForm([Vehicule? v]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/vehicules/form'),
        builder: (_) => VehiculeFormScreen(
          jwtToken: _token,
          id: v?.id,
          vehiculeRequest: v == null
              ? null
              : VehiculeRequest(
                  immatriculation: v.immatriculation,
                  marque: v.marque,
                  modele: v.modele,
                  quotaCarburant: v.quotaCarburant,
                  carburantId: v.carburantId,
                  userId: v.utilisateurId,
                ),
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _delete(Vehicule v) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer ${v.immatriculation} ?',
      message: '${v.marque} ${v.modele} ne pourra plus faire l\'objet de demandes de carburant.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<VehiculeProvider>().removeVehicule(v.id, jwtToken: _token);
      if (mounted) showAppSnack(context, 'Véhicule supprimé.', tone: Tone.success);
    } catch (_) {
      if (mounted) showAppSnack(context, 'La suppression a échoué.', tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VehiculeProvider>();
    final q = _search.toLowerCase();
    final list = provider.vehicules
        .where((v) => '${v.immatriculation} ${v.marque} ${v.modele} ${v.utilisateurNom}'.toLowerCase().contains(q))
        .toList();
    final quotaTotal = provider.vehicules.fold<double>(0, (s, v) => s + v.quotaCarburant);

    return MainLayout(
      title: 'Véhicules',
      jwtToken: _token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Flotte de véhicules',
            subtitle: provider.vehicules.isEmpty
                ? 'Les véhicules pour lesquels vos équipes demandent du carburant.'
                : '${provider.vehicules.length} véhicules · quota total ${formatNumber(quotaTotal)} L',
            actions: [
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ajouter un véhicule'),
              ),
            ],
          ),
          SearchField(hint: 'Immatriculation, marque…', onChanged: (v) => setState(() => _search = v)),
          const SizedBox(height: AppSpacing.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: provider.loading && provider.vehicules.isEmpty
                ? const LoadingView()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : list.isEmpty
                        ? EmptyState(
                            icon: Icons.directions_car_outlined,
                            title: provider.vehicules.isEmpty ? 'Aucun véhicule' : 'Aucun résultat',
                            message: provider.vehicules.isEmpty
                                ? 'Enregistrez les véhicules de votre flotte avec leur quota mensuel.'
                                : 'Modifiez votre recherche.',
                            action: provider.vehicules.isEmpty
                                ? FilledButton(onPressed: () => _openForm(), child: const Text('Ajouter un véhicule'))
                                : null,
                          )
                        : AppDataTable(
                            columns: const [
                              DataColumn(label: Text('IMMATRICULATION')),
                              DataColumn(label: Text('VÉHICULE')),
                              DataColumn(label: Text('CARBURANT')),
                              DataColumn(label: Text('QUOTA'), numeric: true),
                              DataColumn(label: Text('RESPONSABLE')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final v in list)
                                DataRow(cells: [
                                  DataCell(_Plate(v.immatriculation)),
                                  DataCell(Text('${v.marque} ${v.modele}'.trim().isEmpty ? '—' : '${v.marque} ${v.modele}')),
                                  DataCell(Text(v.carburantNom.isEmpty ? '—' : v.carburantNom)),
                                  DataCell(Text('${formatNumber(v.quotaCarburant)} L')),
                                  DataCell(Text(v.utilisateurNom.isEmpty ? '—' : v.utilisateurNom)),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(
                                      tooltip: 'Modifier',
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _openForm(v),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: Tone.danger.fg),
                                      onPressed: () => _delete(v),
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

/// Plaque d'immatriculation stylisée.
class _Plate extends StatelessWidget {
  const _Plate(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        text.isEmpty ? '—' : text.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}
