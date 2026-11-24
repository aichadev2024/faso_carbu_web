import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/role.dart';
import '../providers/carburant_provider.dart';
import '../providers/demande_provider.dart';
import '../providers/station_provider.dart';
import '../providers/user_provider.dart';
import '../providers/vehicule_provider.dart';
import 'main_layout.dart';

class DemandeFormScreen extends StatefulWidget {
  const DemandeFormScreen({super.key});

  @override
  State<DemandeFormScreen> createState() => _DemandeFormScreenState();
}

class _DemandeFormScreenState extends State<DemandeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantiteCtrl = TextEditingController();
  String? _carburant;
  String? _station;
  String? _vehicule;
  String? _chauffeur;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _quantiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final token = Session.token;
    try {
      await Future.wait([
        context.read<UserProvider>().loadUsers(),
        context.read<StationProvider>().loadStations(jwtToken: token),
        context.read<VehiculeProvider>().loadVehicules(jwtToken: token),
        context.read<CarburantProvider>().loadCarburants(token),
      ]);
    } catch (_) {
      _error = 'Certaines listes n\'ont pas pu être chargées.';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final provider = context.read<DemandeProvider>();
    try {
      await provider.createDemande(
        carburantId: int.parse(_carburant!),
        stationId: int.parse(_station!),
        vehiculeId: int.parse(_vehicule!),
        chauffeurId: _chauffeur!,
        quantite: double.parse(_quantiteCtrl.text.replaceAll(',', '.')),
        jwtToken: Session.token,
      );
      if (provider.errorMessage != null) throw Exception(provider.errorMessage);
      if (!mounted) return;
      showAppSnack(context, 'Demande créée.', tone: Tone.success);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = 'La demande n\'a pas pu être créée. Vérifiez les informations saisies.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carburants = context.watch<CarburantProvider>().carburants;
    final stations = context.watch<StationProvider>().stations;
    final vehicules = context.watch<VehiculeProvider>().vehicules;
    final chauffeurs = context.watch<UserProvider>().users.where((u) => u.role == Role.CHAUFFEUR).toList();

    return MainLayout(
      title: 'Nouvelle demande',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Demandes'),
          const PageHeader(
            title: 'Nouvelle demande',
            subtitle: 'Demandez du carburant pour un véhicule et un chauffeur.',
          ),
          if (_loading)
            const LoadingView(message: 'Chargement des listes…')
          else
            Form(
              key: _formKey,
              child: FormLayout(
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: AppSpacing.sm),
                    PrimaryButton(label: 'Créer la demande', icon: Icons.send_rounded, onPressed: _submit, loading: _saving),
                  ],
                ),
                children: [
                  if (_error != null) InlineAlert(message: _error!),
                  FieldRow(children: [
                    AppDropdown<String>(
                      label: 'Carburant',
                      required: true,
                      icon: Icons.local_gas_station_outlined,
                      hint: 'Choisir',
                      value: _carburant,
                      items: [for (final c in carburants) DropdownMenuItem(value: c.id.toString(), child: Text(c.nom))],
                      onChanged: (v) => setState(() => _carburant = v),
                    ),
                    AppTextField(
                      label: 'Quantité (litres)',
                      required: true,
                      controller: _quantiteCtrl,
                      hint: 'Ex. 50',
                      icon: Icons.water_drop_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final q = double.tryParse((v ?? '').replaceAll(',', '.'));
                        if (q == null || q <= 0) return 'Quantité invalide';
                        return null;
                      },
                    ),
                  ]),
                  AppDropdown<String>(
                    label: 'Station',
                    required: true,
                    icon: Icons.place_outlined,
                    hint: stations.isEmpty ? 'Aucune station disponible' : 'Choisir une station',
                    value: _station,
                    items: [
                      for (final s in stations)
                        DropdownMenuItem(value: s.id.toString(), child: Text('${s.nom} · ${s.ville}')),
                    ],
                    onChanged: (v) => setState(() => _station = v),
                  ),
                  FieldRow(children: [
                    AppDropdown<String>(
                      label: 'Véhicule',
                      required: true,
                      icon: Icons.directions_car_outlined,
                      hint: vehicules.isEmpty ? 'Aucun véhicule' : 'Choisir',
                      value: _vehicule,
                      items: [
                        for (final v in vehicules)
                          DropdownMenuItem(value: v.id.toString(), child: Text('${v.immatriculation} · ${v.marque} ${v.modele}')),
                      ],
                      onChanged: (v) => setState(() => _vehicule = v),
                    ),
                    AppDropdown<String>(
                      label: 'Chauffeur',
                      required: true,
                      icon: Icons.badge_outlined,
                      hint: chauffeurs.isEmpty ? 'Aucun chauffeur' : 'Choisir',
                      value: _chauffeur,
                      items: [
                        for (final c in chauffeurs)
                          DropdownMenuItem(value: c.id.toString(), child: Text('${c.prenom} ${c.nom}')),
                      ],
                      onChanged: chauffeurs.isEmpty ? null : (v) => setState(() => _chauffeur = v),
                    ),
                  ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
