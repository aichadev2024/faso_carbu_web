import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/push_notification_service.dart';
import '../services/api_service.dart';
import 'package:logger/logger.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../providers/station_provider.dart';
import '../providers/vehicule_provider.dart';
import '../providers/demande_provider.dart';
import 'ForgotPasswordScreen.dart';

var logger = Logger();
const String baseUrl = 'https://faso-carbu-backend-2.onrender.com/api';

/// Widget pour afficher plusieurs phrases qui changent automatiquement
class RotatingText extends StatefulWidget {
  const RotatingText({super.key});

  @override
  _RotatingTextState createState() => _RotatingTextState();
}

class _RotatingTextState extends State<RotatingText> {
  final List<String> messages = [
    "Bienvenue sur FasoCarbu !\n\nGérez vos tickets carburant en toute simplicité\net restez maître de votre consommation.",
    "Ravi de vous revoir !\n\nAccédez facilement à vos services\net restez connecté à tout moment.",
    "Votre mobilité, notre priorité.\n\nConnectez-vous pour continuer.",
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Change toutes les 5 secondes
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 5));
      if (!mounted) return false;
      setState(() {
        _currentIndex = (_currentIndex + 1) % messages.length;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Text(
        messages[_currentIndex],
        key: ValueKey<int>(_currentIndex),
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _loading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = "Veuillez remplir tous les champs");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'motDePasse': password}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final jwtToken = data['token'] ?? '';
        final role = data['role'] ?? '';
        final nom = data['nom'] ?? '';
        final prenom = data['prenom'] ?? '';
        final userId = (data['id'] ?? '').toString();

        await ApiService.saveToken(jwtToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', email);
        await prefs.setString('role', role);
        await prefs.setString('nom', nom);
        await prefs.setString('prenom', prenom);
        await prefs.setString('userId', userId);

        try {
          final pushService = PushNotificationService();
          final fcmToken = await pushService.getTokenSafe();
          if (fcmToken != null) {
            await pushService.sendTokenToBackend(
              fcmToken: fcmToken,
              userId: userId,
              jwtToken: jwtToken,
            );
          }
        } catch (e) {
          logger.w("Impossible de récupérer le token FCM Web : $e");
        }

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final vehiculeProvider = Provider.of<VehiculeProvider>(
          context,
          listen: false,
        );
        final stationProvider = Provider.of<StationProvider>(
          context,
          listen: false,
        );
        final demandeProvider = Provider.of<DemandeProvider>(
          context,
          listen: false,
        );

        await userProvider.loadUsers();
        await vehiculeProvider.loadVehicules(jwtToken: jwtToken);
        await stationProvider.loadStations(jwtToken: jwtToken);
        await demandeProvider.fetchDemandes(jwtToken);

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/dashboard',
          arguments: {'jwtToken': jwtToken},
        );
      } else {
        final message =
            jsonDecode(response.body)['message'] ?? "Erreur de connexion";
        setState(() => _error = message);
      }
    } catch (e, stackTrace) {
      logger.e("Erreur login: $e", e, stackTrace);
      setState(
        () => _error =
            "Connexion impossible : vérifiez internet ou vos identifiants.",
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFB2FEFA), // bleu clair
              Color(0xFF0ED2F7), // turquoise
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: 700,
                height: 420,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Partie gauche "Welcome Back" avec texte rotatif
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: RotatingText(),
                          ),
                        ),
                      ),
                    ),

                    // Partie droite Login
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              "Login",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),

                            // Email
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                hintText: 'Email',
                                prefixIcon: const Icon(Icons.email),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mot de passe
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),
                            if (_error != null)
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),

                            const SizedBox(height: 16),

                            // Bouton connexion
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _loading
                                    ? null
                                    : () => _login(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667EEA),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _loading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      )
                                    : const Text(
                                        'Connexion',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Mot de passe oublié?',
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("Vous n'avez pas de compte?"),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/register-gestionnaire',
                                    );
                                  },
                                  child: const Text(
                                    'S\'inscrire',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
