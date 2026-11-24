import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/widgets/app_widgets.dart';
import 'main_layout.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.token});
  final String token;

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ancien = TextEditingController();
  final _nouveau = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;
  bool _show = false;
  String? _error;
  bool _done = false;

  @override
  void dispose() {
    _ancien.dispose();
    _nouveau.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _done = false;
    });
    try {
      final res = await http.put(
        Uri.parse('${AppConfig.apiUrl}/auth/changer-mot-de-passe'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${widget.token}'},
        body: jsonEncode({
          'email': Session.email,
          'ancienMotDePasse': _ancien.text,
          'nouveauMotDePasse': _nouveau.text,
        }),
      );
      if (res.statusCode == 200) {
        _formKey.currentState!.reset();
        for (final c in [_ancien, _nouveau, _confirm]) {
          c.clear();
        }
        setState(() => _done = true);
      } else {
        String msg = 'Mot de passe actuel incorrect.';
        try {
          msg = jsonDecode(res.body)['message'] ?? msg;
        } catch (_) {}
        setState(() => _error = msg);
      }
    } catch (_) {
      setState(() => _error = 'Serveur injoignable. Réessayez plus tard.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final toggle = IconButton(
      icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
      onPressed: () => setState(() => _show = !_show),
    );
    return MainLayout(
      title: 'Mot de passe',
      jwtToken: widget.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Retour'),
          const PageHeader(
            title: 'Changer le mot de passe',
            subtitle: 'Utilisez au moins 8 caractères, avec des lettres et des chiffres.',
          ),
          Form(
            key: _formKey,
            child: FormLayout(
              maxWidth: 520,
              footer: Align(
                alignment: Alignment.centerRight,
                child: PrimaryButton(label: 'Mettre à jour', onPressed: _submit, loading: _loading),
              ),
              children: [
                if (_done) const InlineAlert(message: 'Mot de passe modifié avec succès.', tone: Tone.success),
                if (_error != null) InlineAlert(message: _error!),
                AppTextField(
                  label: 'Mot de passe actuel',
                  controller: _ancien,
                  required: true,
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_show,
                  suffix: toggle,
                ),
                AppTextField(
                  label: 'Nouveau mot de passe',
                  controller: _nouveau,
                  required: true,
                  icon: Icons.key_outlined,
                  obscureText: !_show,
                  validator: (v) {
                    if (v == null || v.length < 8) return '8 caractères minimum';
                    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
                      return 'Mélangez lettres et chiffres';
                    }
                    if (v == _ancien.text) return 'Doit être différent de l\'actuel';
                    return null;
                  },
                ),
                AppTextField(
                  label: 'Confirmer le nouveau mot de passe',
                  controller: _confirm,
                  required: true,
                  icon: Icons.key_outlined,
                  obscureText: !_show,
                  validator: (v) => v != _nouveau.text ? 'Les mots de passe ne correspondent pas' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
