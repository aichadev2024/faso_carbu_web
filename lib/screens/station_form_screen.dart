import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/station_provider.dart';
import '../dtos/station_avec_admin_request.dart';

class StationFormScreen extends StatefulWidget {
  final String jwtToken;

  const StationFormScreen({Key? key, required this.jwtToken}) : super(key: key);

  @override
  State<StationFormScreen> createState() => _StationFormScreenState();
}

class _StationFormScreenState extends State<StationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomStation = TextEditingController();
  final _adresseStation = TextEditingController();
  final _villeStation = TextEditingController();
  final _nomAdmin = TextEditingController();
  final _prenomAdmin = TextEditingController();
  final _emailAdmin = TextEditingController();
  final _telAdmin = TextEditingController();
  final _mdpAdmin = TextEditingController();
  final _confirmMdp = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void dispose() {
    _nomStation.dispose();
    _adresseStation.dispose();
    _villeStation.dispose();
    _nomAdmin.dispose();
    _prenomAdmin.dispose();
    _emailAdmin.dispose();
    _telAdmin.dispose();
    _mdpAdmin.dispose();
    _confirmMdp.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final request = StationAvecAdminRequest(
      nomStation: _nomStation.text.trim(),
      adresseStation: _adresseStation.text.trim(),
      villeStation: _villeStation.text.trim(),
      nomAdmin: _nomAdmin.text.trim(),
      prenomAdmin: _prenomAdmin.text.trim(),
      emailAdmin: _emailAdmin.text.trim(),
      motDePasseAdmin: _mdpAdmin.text.trim(),
      telephoneAdmin: _telAdmin.text.trim(),
    );

    try {
      await Provider.of<StationProvider>(
        context,
        listen: false,
      ).addStation(request, jwtToken: widget.jwtToken);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Station + Admin créés avec succès'),
          backgroundColor: Colors.teal,
        ),
      );
      _formKey.currentState!.reset();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    bool showToggle = false,
    VoidCallback? onToggle,
    TextInputType type = TextInputType.text,
    IconData icon = Icons.edit,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: type,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Champ requis';
        if (ctrl == _confirmMdp && v != _mdpAdmin.text) {
          return 'Les mots de passe ne correspondent pas';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.teal.shade700),
        suffixIcon: showToggle
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: Colors.teal.shade600,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: Colors.teal.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer Station + Admin'),
        backgroundColor: Colors.teal.shade600,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 10,
                shadowColor: Colors.teal.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations Station',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _input('Nom Station', _nomStation),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _input('Ville', _villeStation),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _input('Nom Station', _nomStation),
                                  const SizedBox(height: 12),
                                  _input('Ville', _villeStation),
                                ],
                              ),
                        const SizedBox(height: 12),
                        _input(
                          'Adresse',
                          _adresseStation,
                          icon: Icons.location_on,
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.teal.shade300, thickness: 1.5),
                        const SizedBox(height: 10),
                        Text(
                          'Informations Admin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        isWide
                            ? Row(
                                children: [
                                  Expanded(child: _input('Nom', _nomAdmin)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _input('Prénom', _prenomAdmin),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _input('Nom', _nomAdmin),
                                  const SizedBox(height: 12),
                                  _input('Prénom', _prenomAdmin),
                                ],
                              ),
                        const SizedBox(height: 12),
                        _input(
                          'Email',
                          _emailAdmin,
                          type: TextInputType.emailAddress,
                          icon: Icons.email,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          'Téléphone',
                          _telAdmin,
                          type: TextInputType.phone,
                          icon: Icons.phone,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          'Mot de passe',
                          _mdpAdmin,
                          obscure: !_showPassword,
                          showToggle: true,
                          onToggle: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icons.lock,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          'Confirmer mot de passe',
                          _confirmMdp,
                          obscure: !_showConfirmPassword,
                          showToggle: true,
                          onToggle: () => setState(
                            () => _showConfirmPassword = !_showConfirmPassword,
                          ),
                          icon: Icons.lock_outline,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _submit,
                            icon: const Icon(Icons.save),
                            label: Text(
                              _isLoading
                                  ? 'Création...'
                                  : 'Créer Station + Admin',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor: Colors.teal.withValues(alpha: 0.4),
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
}
