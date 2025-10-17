import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

var logger = Logger();

class ChangePasswordScreen extends StatefulWidget {
  final String token;

  const ChangePasswordScreen({super.key, required this.token});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ancienController = TextEditingController();
  final _nouveauController = TextEditingController();
  bool _loading = false;
  String? _message;
  bool _showAncien = false;
  bool _showNouveau = false;

  final Color vertPetrole = const Color(0xFF006666); // 💚 couleur principale

  Future<void> _changerMotDePasse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _message = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    try {
      final response = await http.put(
        Uri.parse(
          "https://faso-carbu-backend-2.onrender.com/api/auth/changer-mot-de-passe",
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'email': email,
          'ancienMotDePasse': _ancienController.text,
          'nouveauMotDePasse': _nouveauController.text,
        }),
      );
      logger.i(response.statusCode);
      logger.i(response.body);

      if (response.statusCode == 200) {
        setState(() => _message = "✅ Mot de passe modifié avec succès");
        _ancienController.clear();
        _nouveauController.clear();
      } else {
        final msg = jsonDecode(response.body)['message'] ?? 'Erreur inconnue';
        setState(() => _message = "❌ Échec : $msg");
      }
    } catch (e) {
      setState(() => _message = "❌ Erreur réseau : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Changer le mot de passe"),
        backgroundColor: vertPetrole,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 70, color: vertPetrole),
                  const SizedBox(height: 20),
                  Text(
                    "Modification du mot de passe",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: vertPetrole,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Champ ancien mot de passe
                  TextFormField(
                    controller: _ancienController,
                    obscureText: !_showAncien,
                    decoration: InputDecoration(
                      labelText: "Ancien mot de passe",
                      labelStyle: TextStyle(color: vertPetrole),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showAncien ? Icons.visibility_off : Icons.visibility,
                          color: vertPetrole,
                        ),
                        onPressed: () =>
                            setState(() => _showAncien = !_showAncien),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: vertPetrole, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 4)
                        ? 'Entrer un mot de passe valide'
                        : null,
                  ),

                  const SizedBox(height: 16),

                  // Champ nouveau mot de passe
                  TextFormField(
                    controller: _nouveauController,
                    obscureText: !_showNouveau,
                    decoration: InputDecoration(
                      labelText: "Nouveau mot de passe",
                      labelStyle: TextStyle(color: vertPetrole),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showNouveau
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: vertPetrole,
                        ),
                        onPressed: () =>
                            setState(() => _showNouveau = !_showNouveau),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: vertPetrole, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) => (value == null || value.length < 4)
                        ? 'Mot de passe trop court'
                        : null,
                  ),

                  const SizedBox(height: 24),

                  _loading
                      ? CircularProgressIndicator(color: vertPetrole)
                      : ElevatedButton.icon(
                          onPressed: _changerMotDePasse,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text("Confirmer le changement"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: vertPetrole,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                  if (_message != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message!.contains("✅")
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
