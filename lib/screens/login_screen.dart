import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/logo.dart';
import '../core/widgets/ticket_card.dart';
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
    Widget feature(IconData icon, String label) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: AppColors.brandOnDark),
            const SizedBox(width: 8),
            Text(label, style: t.labelMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          ]),
        );

    final exemple = TicketData(
      id: '128',
      statut: 'EN_ATTENTE',
      quantite: 40,
      montant: 32800,
      carburant: 'Gasoil',
      station: 'Station partenaire',
      beneficiaire: 'Votre chauffeur',
      dateEmission: DateTime.now(),
    );

    return Container(
      decoration: const BoxDecoration(gradient: inkGradient),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -120,
            top: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [AppColors.brand.withValues(alpha: 0.40), AppColors.brand.withValues(alpha: 0)]),
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: -140,
            child: Opacity(opacity: 0.06, child: LogoMark(size: 360, withBackground: false, color: Colors.white)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 48, 56, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Logo(size: 40, onDark: true, tagline: 'Gestion du carburant'),
                const Spacer(),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Le carburant de votre flotte,\n'),
                    TextSpan(text: 'sous contrôle.', style: TextStyle(color: AppColors.brandOnDark)),
                  ]),
                  style: t.displaySmall?.copyWith(color: Colors.white, fontSize: 38, height: 1.15),
                ),
                const SizedBox(height: AppSpacing.lg),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Text(
                    'Demandes, tickets QR et consommations réunis dans un seul tableau de bord, '
                    'pour vos équipes comme pour les stations partenaires.',
                    style: t.bodyLarge?.copyWith(color: Colors.white.withValues(alpha: 0.68), height: 1.5),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  feature(Icons.task_alt_rounded, 'Validation en un clic'),
                  feature(Icons.qr_code_2_rounded, 'Tickets QR sécurisés'),
                  feature(Icons.insights_rounded, 'Rapports détaillés'),
                ]),
                const SizedBox(height: 40),
                // Aperçu d'un ticket, légèrement incliné.
                Align(
                  alignment: Alignment.centerLeft,
                  child: Transform.rotate(
                    angle: -0.045,
                    child: Container(
                      width: 360,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 40, offset: const Offset(0, 20))],
                      ),
                      child: Theme(data: AppTheme.light(), child: TicketCard(data: exemple, compact: true)),
                    ),
                  ),
                ),
                const Spacer(),
                Text('© ${DateTime.now().year} FasoCarbu', style: t.bodySmall?.copyWith(color: AppColors.textMutedDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
