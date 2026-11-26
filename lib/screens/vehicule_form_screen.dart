import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../dtos/vehicule_request.dart';
import '../models/carburant.dart';
import '../providers/vehicule_provider.dart';
import 'main_layout.dart';

class VehiculeFormScreen extends StatefulWidget {
  const VehiculeFormScreen({super.key, this.id, this.vehiculeRequest, required this.jwtToken});

  final String? id;
  final VehiculeRequest? vehiculeRequest;
  final String jwtToken;

  @override
  State<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends State<VehiculeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _immatriculation = TextEditingController();
  final _marque = TextEditingController();
  final _modele = TextEditingController();
  final _quota = TextEditingController();

  List<Carburant> _carburants = [];
  int? _carburantId;
  bool _loadingCarburants = true;
  bool _saving = false;

  bool get _isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    final r = widget.vehiculeRequest;
    if (r != null) {
      _immatriculation.text = r.immatriculation;
      _marque.text = r.marque;
      _modele.text = r.modele;
      _quota.text = r.quotaCarburant.toStringAsFixed(r.quotaCarburant % 1 == 0 ? 0 : 1);
      _carburantId = int.tryParse(r.carburantId);
    }
    _loadCarburants();
  }

  @override
  void dispose() {
    for (final c in [_immatriculation, _marque, _modele, _quota]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCarburants() async {
    try {
      final list = await CarburantService().getAllCarburants(jwtToken: widget.jwtToken);
      // Un même carburant peut exister dans plusieurs stations : on dédoublonne par nom.
      final seen = <String>{};
      final unique = list.where((c) => seen.add(c.nom.toLowerCase())).toList();
      if (!mounted) return;
      setState(() {
        _carburants = unique;
        if (_carburantId != null && !unique.any((c) => c.id == _carburantId)) {
          final current = list.where((c) => c.id == _carburantId);
          if (current.isNotEmpty) _carburants = [...unique, current.first];
        }
      });
    } catch (_) {
      if (mounted) showAppSnack(context, 'Liste des carburants indisponible.', tone: Tone.warning);
    } finally {
      if (mounted) setState(() => _loadingCarburants = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final request = VehiculeRequest(
      immatriculation: _immatriculation.text.trim().toUpperCase(),
      marque: _marque.text.trim(),
      modele: _modele.text.trim(),
      quotaCarburant: double.tryParse(_quota.text.replaceAll(',', '.')) ?? 0,
      carburantId: _carburantId.toString(),
      userId: widget.vehiculeRequest?.userId.isNotEmpty == true ? widget.vehiculeRequest!.userId : Session.userId,
    );
    final provider = context.read<VehiculeProvider>();
    if (_isEdit) {
      await provider.editVehicule(widget.id!, request, jwtToken: widget.jwtToken);
    } else {
      await provider.addVehicule(request, jwtToken: widget.jwtToken);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnack(context, _isEdit ? 'Véhicule mis à jour.' : 'Véhicule ajouté.', tone: Tone.success);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Modifier le véhicule' : 'Nouveau véhicule';
    return MainLayout(
      title: title,
      jwtToken: widget.jwtToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Véhicules'),
          PageHeader(
            eyebrow: 'Véhicules',
            icon: Icons.directions_car_rounded,
            title: title,
            subtitle: 'Le quota définit le volume mensuel autorisé pour ce véhicule.',
          ),
          Form(
            key: _formKey,
            child: FormLayout(
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(label: _isEdit ? 'Enregistrer' : 'Ajouter le véhicule', onPressed: _submit, loading: _saving),
                ],
              ),
              children: [
                AppTextField(
                  label: 'Immatriculation',
                  controller: _immatriculation,
                  required: true,
                  hint: 'Ex. 11 JK 4521',
                  icon: Icons.pin_outlined,
                ),
                FieldRow(children: [
                  AppTextField(label: 'Marque', controller: _marque, required: true, hint: 'Ex. Toyota'),
                  AppTextField(label: 'Modèle', controller: _modele, required: true, hint: 'Ex. Hilux'),
                ]),
                FieldRow(children: [
                  AppDropdown<int>(
                    label: 'Carburant',
                    required: true,
                    icon: Icons.local_gas_station_outlined,
                    hint: _loadingCarburants ? 'Chargement…' : 'Choisir',
                    value: _carburants.any((c) => c.id == _carburantId) ? _carburantId : null,
                    items: [for (final c in _carburants) DropdownMenuItem(value: c.id, child: Text(c.nom))],
                    onChanged: (v) => setState(() => _carburantId = v),
                  ),
                  AppTextField(
                    label: 'Quota mensuel (litres)',
                    controller: _quota,
                    required: true,
                    hint: 'Ex. 200',
                    icon: Icons.water_drop_outlined,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final q = double.tryParse((v ?? '').replaceAll(',', '.'));
                      return (q == null || q < 0) ? 'Quota invalide' : null;
                    },
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
