import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🎨 Couleur principale
const vertPetrole = Color(0xFF006A6A);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkOnboardingSeen();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  Future<void> _checkOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool('onboarding_seen') ?? false;

    if (seen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, "/login");
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEAF4F4), Colors.white],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isDesktop = constraints.maxWidth > 700;

              return Center(
                child: SizedBox(
                  width: isDesktop ? 700 : double.infinity,
                  child: Column(
                    children: [
                      // ⏭️ Passer
                      Align(
                        alignment: Alignment.topRight,
                        child: TextButton(
                          onPressed: _finishOnboarding,
                          child: const Text(
                            "Passer",
                            style: TextStyle(color: vertPetrole),
                          ),
                        ),
                      ),

                      Expanded(
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // Important pour SingleChildScrollView
                                children: [
                                  // 🖼️ Image globale
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.08,
                                          ),
                                          blurRadius: 20,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      "assets/images/onboarding_overview.png",
                                      height: isDesktop ? 320 : 240,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // 🏷️ Titre
                                  const Text(
                                    "Gérez votre carburant intelligemment",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: vertPetrole,
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // 📝 Description
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 36,
                                    ),
                                    child: Text(
                                      "Centralisez la gestion de vos stations, automatisez les tickets carburants et suivez vos consommations en temps réel.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey.shade700,
                                        height: 1.6,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 40,
                                  ), // un peu d'espace en bas pour le scroll
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ▶️ Bouton Commencer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _finishOnboarding,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: vertPetrole,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              "Commencer",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
