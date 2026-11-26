import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'logo.dart';

/// Mise en page des écrans d'authentification secondaires
/// (mot de passe oublié, réinitialisation, inscription) : carte centrée
/// sur un fond aux couleurs de la marque.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 460,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double maxWidth;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: inkGradient),
        child: Stack(
          children: [
            Positioned(
              right: -140,
              top: -140,
              child: Container(
                width: 460,
                height: 460,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppColors.brand.withValues(alpha: 0.40), AppColors.brand.withValues(alpha: 0)]),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: Logo(size: 40, onDark: true, tagline: 'Gestion du carburant')),
                      const SizedBox(height: AppSpacing.xxl),
                      Card(
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(title, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              Text(subtitle, style: t.bodyMedium),
                              const SizedBox(height: AppSpacing.xl),
                              child,
                            ],
                          ),
                        ),
                      ),
                      if (footer != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Theme(
                          data: Theme.of(context).copyWith(
                            textTheme: t.apply(bodyColor: Colors.white70, displayColor: Colors.white),
                          ),
                          child: footer!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
