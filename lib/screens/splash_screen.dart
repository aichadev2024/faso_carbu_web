import 'package:flutter/material.dart';

import '../core/session.dart';
import 'main_layout.dart';

/// Écran de démarrage : redirige vers le tableau de bord si une session
/// existe, sinon vers la connexion.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        Session.isLoggedIn ? '/dashboard' : '/login',
        arguments: Session.routeArgs,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: BrandMark(size: 44)),
    );
  }
}
