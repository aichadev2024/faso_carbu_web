import 'package:flutter/material.dart';

import '../../screens/main_layout.dart' show BrandMark;
import '../theme/app_theme.dart';

/// Mise en page des écrans d'authentification secondaires
/// (mot de passe oublié, réinitialisation, inscription) : carte centrée.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.maxWidth = 440,
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark()),
                const SizedBox(height: AppSpacing.xxl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(title, style: t.headlineSmall),
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle, style: t.bodyMedium),
                        const SizedBox(height: AppSpacing.xl),
                        child,
                      ],
                    ),
                  ),
                ),
                if (footer != null) ...[const SizedBox(height: AppSpacing.lg), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
