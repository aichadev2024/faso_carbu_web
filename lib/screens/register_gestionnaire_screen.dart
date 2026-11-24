import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/auth_scaffold.dart';
import '../models/role.dart' as role_models;
import '../models/user.dart' as user_models;
import '../providers/user_provider.dart';

/// Inscription d'une nouvelle entreprise et de son gestionnaire.
class RegisterGestionnaireScreen extends StatefulWidget {
  const RegisterGestionnaireScreen({super.key});

  @override
  State<RegisterGestionnaireScreen> createState() => _RegisterGestionnaireScreenState();
}

class _RegisterGestionnaireScreenState extends State<RegisterGestionnaireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _motDePasse = TextEditingController();
  final _confirm = TextEditingController();
  final _nomEntreprise = TextEditingController();
  final _adresseEntreprise = TextEditingController();

  bool _loading = false;
  bool _show = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _telephone, _motDePasse, _confirm, _nomEntreprise, _adresseEntreprise]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final user = user_models.User(
      nom: _nom.text.trim(),
      prenom: _prenom.text.trim(),
      email: _email.text.trim(),
      telephone: _telephone.text.trim(),
      role: role_models.Role.GESTIONNAIRE,
      actif: true,
    );
    try {
      await context.read<UserProvider>().registerGestionnaire(
            user: user,
            motDePasse: _motDePasse.text.trim(),
            nomEntreprise: _nomEntreprise.text.trim(),
            adresseEntreprise: _adresseEntreprise.text.trim(),
          );
      if (!mounted) return;
      showAppSnack(context, 'Compte créé. Vous pouvez vous connecter.', tone: Tone.success);
      Navigator.pushReplacementNamed(context, '/login');
    } catch (_) {
      setState(() => _error = 'Création impossible. L\'email ou le nom d\'entreprise est peut-être déjà utilisé.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(title.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
      );

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: AppSpacing.lg);
    return AuthScaffold(
      maxWidth: 620,
      title: 'Créer un compte entreprise',
      subtitle: 'Vous serez le gestionnaire : vous ajouterez ensuite vos équipes, véhicules et stations.',
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Déjà inscrit ?', style: Theme.of(context).textTheme.bodyMedium),
          TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('Se connecter')),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[InlineAlert(message: _error!), gap],
            _section('Entreprise'),
            gap,
            FieldRow(children: [
              AppTextField(label: 'Nom de l\'entreprise', controller: _nomEntreprise, required: true, icon: Icons.business_outlined),
              AppTextField(label: 'Adresse', controller: _adresseEntreprise, required: true, icon: Icons.place_outlined),
            ]),
            gap,
            _section('Gestionnaire'),
            gap,
            FieldRow(children: [
              AppTextField(label: 'Prénom', controller: _prenom, required: true, icon: Icons.person_outline_rounded),
              AppTextField(label: 'Nom', controller: _nom, required: true),
            ]),
            gap,
            FieldRow(children: [
              AppTextField(
                label: 'Email',
                controller: _email,
                required: true,
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
              ),
              AppTextField(
                label: 'Téléphone',
                controller: _telephone,
                required: true,
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: '+226 70 00 00 00',
              ),
            ]),
            gap,
            FieldRow(children: [
              AppTextField(
                label: 'Mot de passe',
                controller: _motDePasse,
                required: true,
                icon: Icons.lock_outline_rounded,
                obscureText: !_show,
                suffix: IconButton(
                  icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                  onPressed: () => setState(() => _show = !_show),
                ),
                validator: (v) => (v == null || v.length < 8) ? '8 caractères minimum' : null,
              ),
              AppTextField(
                label: 'Confirmation',
                controller: _confirm,
                required: true,
                obscureText: !_show,
                validator: (v) => v != _motDePasse.text ? 'Les mots de passe ne correspondent pas' : null,
              ),
            ]),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Créer mon compte', onPressed: _submit, loading: _loading, expand: true),
          ],
        ),
      ),
    );
  }
}
