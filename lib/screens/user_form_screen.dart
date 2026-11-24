import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/role.dart' as role_model;
import '../models/user.dart';
import '../providers/user_provider.dart';
import 'main_layout.dart';

class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.existing});
  final User? existing;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  final _confirmMdpCtrl = TextEditingController();

  role_model.Role? _role = role_model.Role.DEMANDEUR;
  bool _showPassword = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existing;
    if (u != null) {
      _nomCtrl.text = u.nom;
      _prenomCtrl.text = u.prenom;
      _emailCtrl.text = u.email;
      _telCtrl.text = u.telephone;
      _role = u.role;
    }
  }

  @override
  void dispose() {
    for (final c in [_nomCtrl, _prenomCtrl, _emailCtrl, _telCtrl, _mdpCtrl, _confirmMdpCtrl]) {
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
    final provider = context.read<UserProvider>();
    final payload = User(
      id: _isEdit ? widget.existing!.id : null,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      role: _role!,
      actif: widget.existing?.actif ?? true,
    );
    try {
      if (_isEdit) {
        await provider.editUser(payload);
      } else {
        await provider.addUser(user: payload, motDePasse: _mdpCtrl.text);
      }
      if (!mounted) return;
      showAppSnack(context, _isEdit ? 'Utilisateur modifié.' : 'Utilisateur créé.', tone: Tone.success);
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = 'Enregistrement impossible. Vérifiez que l\'email n\'est pas déjà utilisé.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Modifier l\'utilisateur' : 'Nouvel utilisateur';
    return MainLayout(
      title: title,
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Utilisateurs'),
          PageHeader(
            title: title,
            subtitle: _isEdit
                ? 'Mettez à jour les informations de ${widget.existing!.prenom} ${widget.existing!.nom}.'
                : 'Le compte pourra se connecter avec l\'email et le mot de passe définis ici.',
          ),
          Form(
            key: _formKey,
            child: FormLayout(
              footer: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                  const SizedBox(width: AppSpacing.sm),
                  PrimaryButton(
                    label: _isEdit ? 'Enregistrer' : 'Créer le compte',
                    onPressed: _submit,
                    loading: _saving,
                  ),
                ],
              ),
              children: [
                if (_error != null) InlineAlert(message: _error!),
                FieldRow(children: [
                  AppTextField(label: 'Prénom', controller: _prenomCtrl, required: true, icon: Icons.person_outline_rounded),
                  AppTextField(label: 'Nom', controller: _nomCtrl, required: true),
                ]),
                FieldRow(children: [
                  AppTextField(
                    label: 'Email',
                    controller: _emailCtrl,
                    required: true,
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return 'Ce champ est requis';
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return 'Email invalide';
                      return null;
                    },
                  ),
                  AppTextField(
                    label: 'Téléphone',
                    controller: _telCtrl,
                    hint: '+226 70 00 00 00',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                ]),
                AppDropdown<role_model.Role>(
                  label: 'Rôle',
                  required: true,
                  icon: Icons.badge_outlined,
                  value: _role,
                  items: [
                    for (final r in role_model.Role.values)
                      DropdownMenuItem(value: r, child: Text(Session.roleLabelOf(r.name))),
                  ],
                  onChanged: (v) => setState(() => _role = v),
                ),
                if (!_isEdit)
                  FieldRow(children: [
                    AppTextField(
                      label: 'Mot de passe',
                      controller: _mdpCtrl,
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
                      controller: _confirmMdpCtrl,
                      required: true,
                      obscureText: !_showPassword,
                      validator: (v) => v != _mdpCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
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
