import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'package:gestionnaire_dashboard/models/user.dart';
import 'package:gestionnaire_dashboard/models/role.dart' as role_model;

class UserFormScreen extends StatefulWidget {
  final User? existing;
  const UserFormScreen({super.key, this.existing});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _mdpCtrl = TextEditingController();
  role_model.Role? _selectedRole = role_model.Role.DEMANDEUR;
  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final u = widget.existing!;
      _nomCtrl.text = u.nom;
      _prenomCtrl.text = u.prenom;
      _emailCtrl.text = u.email;
      _telCtrl.text = u.telephone;
      _selectedRole = u.role;
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _telCtrl.dispose();
    _mdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final payload = User(
      id: isEdit
          ? widget.existing!.id
          : null, // 🔹 important : null pour création
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      role: _selectedRole!,
    );

    try {
      if (isEdit) {
        await provider.editUser(payload);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur modifié avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await provider.addUser(user: payload, motDePasse: _mdpCtrl.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur créé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<UserProvider>().loading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.cyan.shade400,
        title: Text(
          isEdit ? 'Modifier un utilisateur' : 'Créer un utilisateur',
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.cyan.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                shadowColor: Colors.cyan.withValues(alpha: 0.4),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          isEdit
                              ? 'Modifiez les informations de l’utilisateur'
                              : 'Bienvenue ! Remplissez le formulaire pour créer un nouvel utilisateur',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyan.shade700,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Nom & Prénom
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                label: 'Nom',
                                controller: _nomCtrl,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le nom est requis'
                                    : null,
                                icon: Icons.badge,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _input(
                                label: 'Prénom',
                                controller: _prenomCtrl,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le prénom est requis'
                                    : null,
                                icon: Icons.person_outline,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Email & Téléphone
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                label: 'Email',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty)
                                    return 'L\'email est requis';
                                  final ok = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  ).hasMatch(v);
                                  return ok ? null : 'Email invalide';
                                },
                                icon: Icons.email,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _input(
                                label: 'Téléphone',
                                controller: _telCtrl,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le téléphone est requis'
                                    : null,
                                icon: Icons.phone,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Rôle
                        DropdownButtonFormField<role_model.Role>(
                          value: _selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Rôle',
                            prefixIcon: const Icon(Icons.admin_panel_settings),
                            filled: true,
                            fillColor: Colors.cyan.shade50,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: role_model.Role.values
                              .map(
                                (r) => DropdownMenuItem(
                                  value: r,
                                  child: Text(r.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedRole = v),
                          validator: (v) =>
                              v == null ? 'Le rôle est requis' : null,
                        ),
                        const SizedBox(height: 16),
                        // Mot de passe
                        if (!isEdit)
                          _input(
                            label: 'Mot de passe',
                            controller: _mdpCtrl,
                            obscureText: true,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Mot de passe requis';
                              if (v.length < 6) return 'Minimum 6 caractères';
                              return null;
                            },
                            icon: Icons.lock,
                          ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _submit,
                            icon: const Icon(Icons.save),
                            label: Text(isEdit ? 'Enregistrer' : 'Créer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan.shade400,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 5,
                              shadowColor: Colors.cyan.withValues(alpha: 0.5),
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
        ),
      ),
    );
  }

  Widget _input({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.cyan.shade700),
        filled: true,
        fillColor: Colors.cyan.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.cyan.shade400, width: 2),
        ),
      ),
    );
  }
}
