import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProfilScreen extends StatefulWidget {
  final String jwtToken;
  final String userId; // ✅ corrigé : String et non int

  const ProfilScreen({super.key, required this.jwtToken, required this.userId});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserProfil();
  }

  Future<void> fetchUserProfil() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://faso-carbu-backend-2.onrender.com/api/utilisateurs/${widget.userId}",
        ),
        headers: {
          "Authorization": "Bearer ${widget.jwtToken}",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          userData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception("Erreur récupération profil: ${response.body}");
      }
    } catch (e) {
      print("❌ Erreur profil: $e");
      setState(() => isLoading = false);
    }
  }

  String _formatRole(String role) {
    switch (role) {
      case 'ROLE_CHAUFFEUR':
        return 'Chauffeur';
      case 'ROLE_GESTIONNAIRE':
        return 'Gestionnaire';
      case 'ROLE_AGENT_STATION':
        return 'Agent de station';
      case 'ROLE_ADMIN_STATION':
        return 'Admin de station';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: const Text("Mon Profil 👤"),
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(
              child: Text(
                "Impossible de charger le profil ❌",
                style: TextStyle(color: Colors.red),
              ),
            )
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ✅ Avatar
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.indigo,
                            child: const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ✅ Nom + rôle
                          Text(
                            "${userData!['nom']} ${userData!['prenom']}",
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatRole(userData!['role']),
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // ✅ Infos utilisateur
                          _buildInfo(Icons.email, "Email", userData!['email']),
                          const Divider(),
                          _buildInfo(
                            Icons.phone,
                            "Téléphone",
                            userData!['telephone'] ?? "Non renseigné",
                          ),

                          const SizedBox(height: 40),

                          // ✅ Boutons action
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/change-password',
                                    arguments: {"jwtToken": widget.jwtToken},
                                  );
                                },
                                icon: const Icon(Icons.lock_reset),
                                label: const Text("Changer le mot de passe"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    "/",
                                    (r) => false,
                                  );
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text("Déconnexion"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
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

  Widget _buildInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo),
          const SizedBox(width: 12),
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}
