import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String baseUrl = 'https://faso-carbu-backend-2.onrender.com/api';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _message;

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (code.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      setState(() => _message = "⚠️ Veuillez remplir tous les champs");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _message = "⚠️ Les mots de passe ne correspondent pas");
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'code': code,
          'nouveauMotDePasse': password,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _message = "✅ Mot de passe réinitialisé avec succès";
        });

        Future.delayed(const Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _message = body['message'] ?? "Erreur lors de la réinitialisation";
        });
      }
    } catch (e) {
      setState(() {
        _message = "⚠️ Erreur serveur ou connexion internet";
      });
    } finally {
      setState(() => _loading = false);
    }
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: isSmall ? double.infinity : 600,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(30),
              child: Column(
                children: [
                  Image.asset('assets/images/Image.web.png', height: 90),
                  const SizedBox(height: 20),
                  const Text(
                    "Réinitialiser le mot de passe",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003B46),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Entrez le code reçu par email et votre nouveau mot de passe.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: "Code OTP",
                      prefixIcon: const Icon(Icons.key_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscure1,
                    decoration: InputDecoration(
                      labelText: "Nouveau mot de passe",
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure1 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscure2,
                    decoration: InputDecoration(
                      labelText: "Confirmer mot de passe",
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure2 ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  if (_message != null)
                    Text(
                      _message!,
                      style: TextStyle(
                        color: _message!.startsWith("✅")
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003B46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Réinitialiser",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text(
                      "Retour à la connexion",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
