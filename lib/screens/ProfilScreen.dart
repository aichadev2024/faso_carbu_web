import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'change_password_screen.dart';

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
    _loadCachedUser();
  }

  /// Charge les infos utilisateur depuis le cache, puis actualise depuis le backend
  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('userData_${widget.userId}');
    if (cached != null) {
      setState(() {
        userData = jsonDecode(cached);
        isLoading = false;
      });
    }
    await fetchUserProfil();
  }

  /// Récupère le profil depuis l’API
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
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          userData = data;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userData_${widget.userId}', jsonEncode(data));
      } else {
        throw Exception("Erreur récupération profil: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Erreur profil: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Met à jour la photo de profil (compatible Web)
  Future<void> _changeProfilePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final bytes = await pickedFile.readAsBytes();

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://faso-carbu-backend-2.onrender.com/api/utilisateurs/${widget.userId}/upload-photo',
        ),
      );

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: pickedFile.name,
      );

      request.files.add(multipartFile);
      request.headers['Authorization'] = 'Bearer ${widget.jwtToken}';

      final response = await request.send();

      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final data = jsonDecode(respStr);
        String newPhotoUrl = data['photoProfil'];

        // Force reload sur le Web en ajoutant un query param unique
        newPhotoUrl += '?t=${DateTime.now().millisecondsSinceEpoch}';

        if (mounted) {
          setState(() {
            userData!['photoUrl'] = newPhotoUrl;
          });
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'userData_${widget.userId}',
          jsonEncode(userData),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Photo de profil mise à jour !')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Échec de la mise à jour de la photo'),
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur upload photo: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Erreur: $e")));
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
      colors: [Color(0xFF009999), Color(0xFF006666)],
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
                      // Photo avec bouton caméra
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 55,
                            backgroundImage:
                                (userData?['photoUrl'] != null &&
                                    userData!['photoUrl'].toString().isNotEmpty)
                                ? NetworkImage(userData!['photoUrl'])
                                : const AssetImage(
                                        'assets/images/avatar_placeholder.png',
                                      )
                                      as ImageProvider,
                            onBackgroundImageError: (_, __) {
                              SchedulerBinding.instance.addPostFrameCallback((
                                _,
                              ) {
                                if (mounted) {
                                  setState(() {
                                    userData!['photoUrl'] = null;
                                  });
                                }
                              });
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: InkWell(
                              onTap: _changeProfilePhoto,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: vertPetrole,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${userData?['nom'] ?? ''} ${userData?['prenom'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        _formatRole(userData?['role'] ?? ''),
                        style: TextStyle(
                          color: vertPetrole,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      _infoText(Icons.email, userData?['email'] ?? ''),
                      if (userData?['telephone'] != null)
                        _infoText(Icons.phone, userData!['telephone']),
                      if (userData?['adresse'] != null)
                        _infoText(Icons.location_on, userData!['adresse']),
                      const SizedBox(height: 24),
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
