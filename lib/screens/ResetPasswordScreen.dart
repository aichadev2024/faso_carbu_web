import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/auth_scaffold.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.email});
  final String email;

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _show = false;
  bool _loading = false;
  bool _done = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': _code.text.trim(),
          'nouveauMotDePasse': _password.text,
        }),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        setState(() => _done = true);
      } else {
        String msg = 'Code invalide ou expiré.';
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
    if (_done) {
      return AuthScaffold(
        title: 'Mot de passe réinitialisé',
        subtitle: 'Vous pouvez maintenant vous connecter avec votre nouveau mot de passe.',
        child: PrimaryButton(
          label: 'Se connecter',
          expand: true,
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
        ),
      );
    }
    final toggle = IconButton(
      icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
      onPressed: () => setState(() => _show = !_show),
    );
    return AuthScaffold(
      title: 'Nouveau mot de passe',
      subtitle: 'Saisissez le code reçu à ${widget.email} et choisissez un nouveau mot de passe.',
      footer: Center(
        child: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Renvoyer un code'),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[InlineAlert(message: _error!), const SizedBox(height: AppSpacing.lg)],
            AppTextField(
              label: 'Code de vérification',
              controller: _code,
              required: true,
              icon: Icons.pin_outlined,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Nouveau mot de passe',
              controller: _password,
              required: true,
              icon: Icons.lock_outline_rounded,
              obscureText: !_show,
              suffix: toggle,
              validator: (v) => (v == null || v.length < 8) ? '8 caractères minimum' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Confirmation',
              controller: _confirm,
              required: true,
              icon: Icons.lock_outline_rounded,
              obscureText: !_show,
              validator: (v) => v != _password.text ? 'Les mots de passe ne correspondent pas' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Réinitialiser', onPressed: _submit, loading: _loading, expand: true),
          ],
        ),
      ),
    );
  }
}
