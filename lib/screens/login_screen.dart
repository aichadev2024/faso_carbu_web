import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../services/push_notification_service.dart';
import 'ForgotPasswordScreen.dart';
import 'main_layout.dart';

final _log = Logger();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'motDePasse': password}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final jwtToken = (data['token'] ?? '').toString();
        final userId = (data['id'] ?? '').toString();

        await Session.save(
          token: jwtToken,
          userId: userId,
          email: email,
          nom: (data['nom'] ?? '').toString(),
          prenom: (data['prenom'] ?? '').toString(),
          role: (data['role'] ?? '').toString(),
        );

        _registerPushToken(userId: userId, jwtToken: jwtToken);

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard', arguments: Session.routeArgs);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        setState(() => _error = 'Email ou mot de passe incorrect.');
      } else {
        String message = 'Connexion impossible (erreur ${response.statusCode}).';
        try {
          message = jsonDecode(response.body)['message'] ?? message;
        } catch (_) {}
        setState(() => _error = message);
      }
    } catch (e) {
      _log.e('Erreur login: $e');
      setState(() => _error = 'Serveur injoignable. Vérifiez votre connexion internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Enregistre le token de notifications push sans bloquer la connexion.
  Future<void> _registerPushToken({required String userId, required String jwtToken}) async {
    try {
      final push = PushNotificationService();
      final fcmToken = await push.getTokenSafe();
      if (fcmToken != null) {
        await push.sendTokenToBackend(fcmToken: fcmToken, userId: userId, jwtToken: jwtToken);
      }
    } catch (e) {
      _log.w('Token FCM web indisponible : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 980;
    return Scaffold(
      body: Row(
        children: [
          if (wide) const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _buildForm(context, showLogo: !wide),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, {required bool showLogo}) {
    final t = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showLogo) ...[
              const Align(alignment: Alignment.centerLeft, child: BrandMark()),
              const SizedBox(height: 40),
            ],
            Text('Connexion', style: t.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text('Accédez à votre espace de gestion du carburant.', style: t.bodyMedium),
            const SizedBox(height: AppSpacing.xxl),
            if (_error != null) ...[
              InlineAlert(message: _error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppTextField(
              label: 'Adresse email',
              controller: _emailController,
              hint: 'nom@entreprise.bf',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Saisissez votre email';
                if (!value.contains('@')) return 'Email invalide';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: 'Mot de passe',
              controller: _passwordController,
              hint: '••••••••',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.isEmpty) ? 'Saisissez votre mot de passe' : null,
              suffix: IconButton(
                tooltip: _obscurePassword ? 'Afficher' : 'Masquer',
                icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                ),
                child: const Text('Mot de passe oublié ?'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(label: 'Se connecter', onPressed: _login, loading: _loading, expand: true),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Nouvelle entreprise ?', style: t.bodyMedium),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/register-gestionnaire'),
                  child: const Text('Créer un compte'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget feature(IconData icon, String title, String text) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 18, color: AppColors.brandOnDark),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(text, style: t.bodyMedium?.copyWith(color: AppColors.sidebarText)),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      color: AppColors.sidebar,
      padding: const EdgeInsets.all(56),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BrandMark(onDark: true),
          const Spacer(),
          Text(
            'Le carburant de votre flotte,\nsous contrôle.',
            style: t.displaySmall?.copyWith(color: Colors.white, fontSize: 34, height: 1.2),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Demandes, tickets QR et consommations réunis dans un seul tableau de bord.',
            style: t.bodyLarge?.copyWith(color: AppColors.sidebarText),
          ),
          const SizedBox(height: 48),
          feature(Icons.assignment_turned_in_outlined, 'Validation des demandes', 'Approuvez ou rejetez les demandes de vos équipes en un clic.'),
          feature(Icons.qr_code_2_rounded, 'Tickets sécurisés', 'Chaque ticket génère un QR code vérifié en station.'),
          feature(Icons.insights_rounded, 'Suivi des consommations', 'Rapports par chauffeur, véhicule et période.'),
          const Spacer(),
          Text('© ${DateTime.now().year} FasoCarbu', style: t.bodySmall?.copyWith(color: AppColors.textMutedDark)),
        ],
      ),
    );
  }
}
