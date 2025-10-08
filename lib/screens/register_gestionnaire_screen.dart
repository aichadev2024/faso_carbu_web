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
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController nomEntrepriseController = TextEditingController();
  final TextEditingController adresseEntrepriseController =
      TextEditingController();

  bool _loading = false;
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
        prefixIcon: Icon(icon, color: Colors.blueAccent),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.blue.shade50.withOpacity(0.3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                children: [
                  /// 🔹 Header avec dégradé
                  Container(
                    height: 160,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent, Colors.purpleAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(30),
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.local_gas_station,
                              size: 35,
                              color: Colors.blueAccent,
                            ),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "FasoCarbu",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔹 Phrase motivante
                  const Text(
                    "Créez votre compte gestionnaire et pilotez vos stations avec simplicité 🚀",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// 🔹 Formulaire contenu dans une carte centrée
                  Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            const Text(
                              'Inscription Gestionnaire',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              label: 'Nom',
                              controller: nomController,
                              icon: Icons.person,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Le nom est requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              label: 'Prénom',
                              controller: prenomController,
                              icon: Icons.person_outline,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Le prénom est requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              label: 'Email',
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email,
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
                              obscureText: true,
                              icon: Icons.lock,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Le mot de passe est requis';
                                }
                                if (v.length < 6) {
                                  return 'Minimum 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              label: 'Téléphone',
                              controller: telephoneController,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Le téléphone est requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              label: 'Nom de l\'entreprise',
                              controller: nomEntrepriseController,
                              icon: Icons.business,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Nom de l\'entreprise requis'
                                  : null,
                            ),
                            const SizedBox(height: 12),

                            _buildTextField(
                              label: 'Adresse de l\'entreprise',
                              controller: adresseEntrepriseController,
                              icon: Icons.location_on,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Adresse de l\'entreprise requise'
                                  : null,
                            ),
                            const SizedBox(height: 18),

                            if (_error != null)
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            const SizedBox(height: 14),

                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 20,
                                ),
                                backgroundColor: Colors.blueAccent,
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
                                      style: TextStyle(fontSize: 15),
                                    ),
                            ),
                            const SizedBox(height: 10),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                "Retour à la connexion",
                                style: TextStyle(color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
