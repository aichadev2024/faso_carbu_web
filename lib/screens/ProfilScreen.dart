import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'change_password_screen.dart'; // 👈 Écran de changement de mot de passe

class ProfilScreen extends StatefulWidget {
  final String jwtToken;
  final String userId;

  const ProfilScreen({super.key, required this.jwtToken, required this.userId});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;

  final Color vertPetrole = const Color(0xFF006666);

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
          userData = jsonDecode(utf8.decode(response.bodyBytes));
        });
      } else {
        throw Exception("Erreur récupération profil: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Erreur profil: $e");
    } finally {
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
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    const vertPetroleGradient = LinearGradient(
      colors: [
        Color(0xFF009999), // clair
        Color(0xFF006666), // foncé
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: vertPetrole))
          : Container(
              decoration: const BoxDecoration(gradient: vertPetroleGradient),
              child: Center(
                child: Container(
                  width: 450,
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Photo
                      CircleAvatar(
                        radius: 55,
                        backgroundImage: userData!['photoUrl'] != null
                            ? NetworkImage(userData!['photoUrl'])
                            : const AssetImage(
                                    'assets/images/avatar_placeholder.png',
                                  )
                                  as ImageProvider,
                      ),
                      const SizedBox(height: 20),

                      // Nom complet
                      Text(
                        "${userData!['nom']} ${userData!['prenom']}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      // Rôle
                      Text(
                        _formatRole(userData!['role']),
                        style: TextStyle(
                          color: vertPetrole,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Ligne de séparation
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),

                      // Infos utilisateur
                      _infoText(Icons.email, userData!['email']),
                      if (userData!['telephone'] != null)
                        _infoText(Icons.phone, userData!['telephone']),
                      if (userData!['adresse'] != null)
                        _infoText(Icons.location_on, userData!['adresse']),

                      const SizedBox(height: 24),

                      // Bouton changement mot de passe
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ChangePasswordScreen(token: widget.jwtToken),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: vertPetrole,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.lock, color: Colors.white),
                        label: const Text(
                          "Changer le mot de passe",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _infoText(IconData icon, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: vertPetrole),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
      ],
    ),
  );
}
