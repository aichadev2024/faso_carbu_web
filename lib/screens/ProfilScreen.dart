import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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
        final decodedBody = utf8.decode(response.bodyBytes);
        setState(() {
          userData = jsonDecode(decodedBody);
          isLoading = false;
        });
      } else {
        throw Exception("Erreur récupération profil: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Erreur profil: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickProfileImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
      // 👉 Ici, tu pourrais envoyer la photo au backend :
      // await uploadProfilePhoto(File(picked.path));
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
    const petrolGreen = Color(0xFF07575B);
    const lightTurquoise = Color(0xFF0E9AA7);
    const backgroundColor = Color(0xFFF5F8FA);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Mon Profil",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: petrolGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: fetchUserProfil,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: lightTurquoise),
            )
          : userData == null
          ? const Center(
              child: Text(
                "Impossible de charger le profil ❌",
                style: TextStyle(color: Colors.redAccent, fontSize: 16),
              ),
            )
          : RefreshIndicator(
              color: lightTurquoise,
              onRefresh: fetchUserProfil,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ✅ En-tête stylé avec dégradé
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [petrolGreen, lightTurquoise],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: _profileImage != null
                                    ? FileImage(_profileImage!)
                                    : (userData!['photoUrl'] != null
                                          ? NetworkImage(userData!['photoUrl'])
                                                as ImageProvider
                                          : const AssetImage(
                                              'assets/images/avatar_placeholder.png',
                                            )),
                              ),
                              Positioned(
                                bottom: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: petrolGreen,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${userData!['nom']} ${userData!['prenom']}",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatRole(userData!['role']),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Carte infos utilisateur
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 8,
                        shadowColor: Colors.black12,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              _buildInfo(
                                Icons.email,
                                "Email",
                                userData!['email'],
                              ),
                              const Divider(),
                              _buildInfo(
                                Icons.phone,
                                "Téléphone",
                                userData!['telephone'] ?? "Non renseigné",
                              ),
                              const Divider(),
                              _buildInfo(
                                Icons.account_box,
                                "Identifiant",
                                userData!['id'].toString(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ Boutons stylés
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
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
                              backgroundColor: lightTurquoise,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
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
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfo(IconData icon, String label, String value) {
    const petrolGreen = Color(0xFF07575B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: petrolGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: petrolGreen),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: petrolGreen,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
