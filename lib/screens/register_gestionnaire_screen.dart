import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart' as user_models;
import '../models/role.dart' as role_models;
import '../providers/user_provider.dart';

class RegisterGestionnaireScreen extends StatefulWidget {
  const RegisterGestionnaireScreen({super.key});

  @override
  State<RegisterGestionnaireScreen> createState() =>
      _RegisterGestionnaireScreenState();
}

class _RegisterGestionnaireScreenState extends State<RegisterGestionnaireScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController motDePasseController = TextEditingController();
  final TextEditingController confirmMotDePasseController =
      TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController nomEntrepriseController = TextEditingController();
  final TextEditingController adresseEntrepriseController =
      TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _error;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    nomController.dispose();
    prenomController.dispose();
    emailController.dispose();
    motDePasseController.dispose();
    confirmMotDePasseController.dispose();
    telephoneController.dispose();
    nomEntrepriseController.dispose();
    adresseEntrepriseController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final user = user_models.User(
      nom: nomController.text.trim(),
      prenom: prenomController.text.trim(),
      email: emailController.text.trim(),
      telephone: telephoneController.text.trim(),
      role: role_models.Role.GESTIONNAIRE,
      actif: true,
    );

    try {
      final responseMessage = await context
          .read<UserProvider>()
          .registerGestionnaire(
            user: user,
            motDePasse: motDePasseController.text.trim(),
            nomEntreprise: nomEntrepriseController.text.trim(),
            adresseEntreprise: adresseEntrepriseController.text.trim(),
          );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(responseMessage)));

      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      setState(() => _error = 'Erreur lors de la création : $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF003B46)),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF003B46), Color(0xFF07575B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                width: isSmall ? double.infinity : 800,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Flex(
                  direction: isSmall ? Axis.vertical : Axis.horizontal,
                  children: [
                    // Partie gauche branding
                    Expanded(
                      flex: 1,
                      child: Container(
                        height: isSmall ? 250 : 420,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF0E9AA7), Color(0xFF003B46)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            bottomLeft: Radius.circular(25),
                          ),
                        ),
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Text(
                              "Créer un compte gestionnaire\n\nRejoignez FasoCarbu et pilotez vos stations simplement.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Partie droite (formulaire)
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(25),
                            bottomRight: Radius.circular(25),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/Image.web.png',
                                height: 90,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Inscription Gestionnaire",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003B46),
                                ),
                              ),
                              const SizedBox(height: 20),

                              _buildTextField(
                                label: 'Nom',
                                controller: nomController,
                                icon: Icons.person,
                                validator: (v) =>
                                    v!.isEmpty ? 'Le nom est requis' : null,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Prénom',
                                controller: prenomController,
                                icon: Icons.person_outline,
                                validator: (v) =>
                                    v!.isEmpty ? 'Le prénom est requis' : null,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Email',
                                controller: emailController,
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  if (!RegExp(
                                    r"^[^@]+@[^@]+\.[^@]+",
                                  ).hasMatch(v)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Mot de passe',
                                controller: motDePasseController,
                                obscureText: _obscurePassword,
                                icon: Icons.lock_outline,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Mot de passe requis';
                                  }
                                  if (v.length < 6) {
                                    return 'Minimum 6 caractères';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Confirmer le mot de passe',
                                controller: confirmMotDePasseController,
                                obscureText: _obscureConfirmPassword,
                                icon: Icons.lock,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    );
                                  },
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'Confirmez le mot de passe';
                                  }
                                  if (v != motDePasseController.text) {
                                    return 'Les mots de passe ne correspondent pas';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Téléphone',
                                controller: telephoneController,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (v) =>
                                    v!.isEmpty ? 'Téléphone requis' : null,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Nom de l’entreprise',
                                controller: nomEntrepriseController,
                                icon: Icons.business,
                                validator: (v) => v!.isEmpty
                                    ? 'Nom de l’entreprise requis'
                                    : null,
                              ),
                              const SizedBox(height: 12),

                              _buildTextField(
                                label: 'Adresse de l’entreprise',
                                controller: adresseEntrepriseController,
                                icon: Icons.location_on,
                                validator: (v) => v!.isEmpty
                                    ? 'Adresse de l’entreprise requise'
                                    : null,
                              ),
                              const SizedBox(height: 20),

                              if (_error != null)
                                Text(
                                  _error!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF003B46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          "S'inscrire",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text(
                                  "Retour à la connexion",
                                  style: TextStyle(color: Color(0xFF003B46)),
                                ),
                              ),
                            ],
                          ),
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
