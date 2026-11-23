import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../dtos/station_avec_admin_request.dart';
import '../providers/station_provider.dart';
import 'main_layout.dart';

/// Création d'une station et de son administrateur en une seule étape.
class StationFormScreen extends StatefulWidget {
  const StationFormScreen({super.key, required this.jwtToken});
  final String jwtToken;

  @override
  State<StationFormScreen> createState() => _StationFormScreenState();
}

class _StationFormScreenState extends State<StationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomStation = TextEditingController();
  final _adresseStation = TextEditingController();
  final _villeStation = TextEditingController();
  final _nomAdmin = TextEditingController();
  final _prenomAdmin = TextEditingController();
  final _emailAdmin = TextEditingController();
  final _telAdmin = TextEditingController();
  final _mdpAdmin = TextEditingController();
  final _confirmMdp = TextEditingController();

  bool _saving = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [
      _nomStation, _adresseStation, _villeStation, _nomAdmin, _prenomAdmin,
      _emailAdmin, _telAdmin, _mdpAdmin, _confirmMdp,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final request = StationAvecAdminRequest(
      nomStation: _nomStation.text.trim(),
      adresseStation: _adresseStation.text.trim(),
      villeStation: _villeStation.text.trim(),
      nomAdmin: _nomAdmin.text.trim(),
      prenomAdmin: _prenomAdmin.text.trim(),
      emailAdmin: _emailAdmin.text.trim(),
      motDePasseAdmin: _mdpAdmin.text.trim(),
      telephoneAdmin: _telAdmin.text.trim(),
    );
    try {
      await context.read<StationProvider>().addStation(request, jwtToken: widget.jwtToken);
      if (!mounted) return;
      showAppSnack(context, 'Station et administrateur créés.', tone: Tone.success);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Création impossible. L\'email de l\'administrateur est peut-être déjà utilisé.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String title, String subtitle) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: t.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: t.bodySmall),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Nouvelle station',
      jwtToken: widget.jwtToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Stations'),
          const PageHeader(
            title: 'Nouvelle station',
            subtitle: 'Ajoutez une station partenaire et le compte de son administrateur.',
          ),
          Form(
            key: _formKey,
            child: FormLayout(
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(label: 'Créer la station', onPressed: _submit, loading: _saving),
                ],
              ),
              children: [
                if (_error != null) InlineAlert(message: _error!),
                _section('Station', 'Informations visibles par vos équipes.'),
                AppTextField(
                  label: 'Nom de la station',
                  controller: _nomStation,
                  required: true,
                  hint: 'Ex. Station Ouaga 2000',
                  icon: Icons.local_gas_station_outlined,
                ),
                FieldRow(children: [
                  AppTextField(label: 'Adresse', controller: _adresseStation, required: true, icon: Icons.place_outlined),
                  AppTextField(label: 'Ville', controller: _villeStation, required: true, hint: 'Ex. Ouagadougou'),
                ]),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                _section('Administrateur de la station', 'Il gérera les carburants et les agents de cette station.'),
                FieldRow(children: [
                  AppTextField(label: 'Prénom', controller: _prenomAdmin, required: true, icon: Icons.person_outline_rounded),
                  AppTextField(label: 'Nom', controller: _nomAdmin, required: true),
                ]),
                FieldRow(children: [
                  AppTextField(
                    label: 'Email',
                    controller: _emailAdmin,
                    required: true,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
                  ),
                  AppTextField(
                    label: 'Téléphone',
                    controller: _telAdmin,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ]),
                FieldRow(children: [
                  AppTextField(
                    label: 'Mot de passe',
                    controller: _mdpAdmin,
                    required: true,
                    icon: Icons.lock_outline_rounded,
                    obscureText: !_showPassword,
                    suffix: IconButton(
                      icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setState(() => _showPassword = !_showPassword),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? '6 caractères minimum' : null,
                  ),
                  AppTextField(
                    label: 'Confirmation',
                    controller: _confirmMdp,
                    required: true,
                    obscureText: !_showPassword,
                    validator: (v) => v != _mdpAdmin.text ? 'Les mots de passe ne correspondent pas' : null,
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
