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
  final _confirmMdpCtrl = TextEditingController();

  role_model.Role? _selectedRole = role_model.Role.DEMANDEUR;
  bool get isEdit => widget.existing != null;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

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
    _confirmMdpCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<UserProvider>();
    final payload = User(
      id: isEdit ? widget.existing!.id : null,
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
            backgroundColor: Colors.teal,
          ),
        );
      } else {
        await provider.addUser(user: payload, motDePasse: _mdpCtrl.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Utilisateur créé avec succès'),
            backgroundColor: Colors.teal,
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
    const petrol = Color(0xFF07575B);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: petrol,
        title: Text(
          isEdit ? 'Modifier un utilisateur' : 'Créer un utilisateur',
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 12,
                shadowColor: petrol.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Text(
                          isEdit
                              ? 'Modifier les informations de l’utilisateur'
                              : 'Créer un nouvel utilisateur',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: petrol,
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
                                icon: Icons.badge,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le nom est requis'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _input(
                                label: 'Prénom',
                                controller: _prenomCtrl,
                                icon: Icons.person_outline,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le prénom est requis'
                                    : null,
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
                                icon: Icons.email,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) {
                                    return 'L\'email est requis';
                                  }
                                  final ok = RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  ).hasMatch(v);
                                  return ok ? null : 'Email invalide';
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _input(
                                label: 'Téléphone',
                                controller: _telCtrl,
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (v) => v == null || v.isEmpty
                                    ? 'Le téléphone est requis'
                                    : null,
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
                            prefixIcon: const Icon(
                              Icons.admin_panel_settings,
                              color: petrol,
                            ),
                            filled: true,
                            fillColor: Colors.teal.shade50,
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

                        // Mot de passe & confirmation
                        if (!isEdit) ...[
                          _passwordInput(
                            label: 'Mot de passe',
                            controller: _mdpCtrl,
                            obscureText: !_showPassword,
                            onToggle: () =>
                                setState(() => _showPassword = !_showPassword),
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
                          const SizedBox(height: 16),
                          _passwordInput(
                            label: 'Confirmer le mot de passe',
                            controller: _confirmMdpCtrl,
                            obscureText: !_showConfirmPassword,
                            onToggle: () => setState(
                              () =>
                                  _showConfirmPassword = !_showConfirmPassword,
                            ),
                            validator: (v) {
                              if (v != _mdpCtrl.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isLoading ? null : _submit,
                            icon: const Icon(Icons.save),
                            label: Text(isEdit ? 'Enregistrer' : 'Créer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: petrol,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
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

  // Champ texte générique
  Widget _input({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
  }) {
    const petrol = Color(0xFF07575B);
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: petrol),
        filled: true,
        fillColor: Colors.teal.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // Champ mot de passe avec icône œil
  Widget _passwordInput({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    const petrol = Color(0xFF07575B);
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock, color: petrol),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: petrol,
          ),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: Colors.teal.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
