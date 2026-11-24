import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/auth_scaffold.dart';
import 'ResetPasswordScreen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _email.text.trim();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (res.statusCode >= 200 && res.statusCode < 300) {
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)));
      } else {
        String msg = 'Aucun compte ne correspond à cet email.';
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
    return AuthScaffold(
      title: 'Mot de passe oublié',
      subtitle: 'Saisissez votre email : nous vous enverrons un code de réinitialisation.',
      footer: Center(
        child: TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          label: const Text('Retour à la connexion'),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[InlineAlert(message: _error!), const SizedBox(height: AppSpacing.lg)],
            AppTextField(
              label: 'Adresse email',
              controller: _email,
              hint: 'nom@entreprise.bf',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              onSubmitted: (_) => _submit(),
              validator: (v) => (v == null || !v.contains('@')) ? 'Email invalide' : null,
            ),
            const SizedBox(height: AppSpacing.xl),
            PrimaryButton(label: 'Envoyer le code', onPressed: _submit, loading: _loading, expand: true),
          ],
        ),
      ),
    );
  }
}
