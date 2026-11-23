import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../core/config/app_config.dart';

class UserService {
  final String baseUrl = AppConfig.apiUrl;

  // 🔹 Récupère tous les utilisateurs (optionnel)
  Future<List<User>> getAllUsers({String search = '', String? jwtToken}) async {
    final url = Uri.parse(
      '$baseUrl/utilisateurs${search.isNotEmpty ? "?search=$search" : ""}',
    );

    try {
      final response = await http.get(
        url,
        headers: jwtToken != null ? {'Authorization': 'Bearer $jwtToken'} : {},
      );

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is List) {
          return decoded
              .map((json) => User.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception("La réponse du backend n'est pas une liste JSON");
        }
      } else {
        throw Exception(
          "Erreur HTTP ${response.statusCode} lors du chargement des utilisateurs",
        );
      }
    } catch (e) {
      throw Exception("Erreur lors du chargement des utilisateurs: $e");
    }
  }

  // 🔹 Récupère le profil de l’utilisateur connecté via son JWT
  Future<User> getCurrentUser({required String jwtToken}) async {
    final url = Uri.parse('$baseUrl/auth/me');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $jwtToken'},
    );

    if (response.statusCode == 200) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception("Impossible de récupérer le profil utilisateur");
    }
  }

  // 🔹 Crée un utilisateur
  Future<User> createUser({
    required User user,
    required String motDePasse,
    String? jwtToken,
  }) async {
    final url = Uri.parse('$baseUrl/utilisateurs/ajouter');
    final Map<String, dynamic> body = Map<String, dynamic>.from(user.toJson());
    body.remove("id");
    body["motDePasse"] = motDePasse;

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        if (jwtToken != null) "Authorization": "Bearer $jwtToken",
      },
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return User.fromJson(data);
    } else {
      throw Exception("Erreur lors de la création de l’utilisateur");
    }
  }

  // 🔹 Inscription d’un gestionnaire
  Future<String> registerGestionnaire({
    required User user,
    required String motDePasse,
    required String nomEntreprise,
    required String adresseEntreprise,
    String? jwtToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final Map<String, dynamic> body = Map<String, dynamic>.from(user.toJson());
    body.remove("id");
    body.addAll({
      "motDePasse": motDePasse,
      "nomEntreprise": nomEntreprise,
      "adresseEntreprise": adresseEntreprise,
    });

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        if (jwtToken != null) "Authorization": "Bearer $jwtToken",
      },
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return data['message'] ?? "Utilisateur créé avec succès";
    } else {
      throw Exception("Erreur lors de l’inscription du gestionnaire");
    }
  }

  // 🔹 Met à jour un utilisateur
  Future<void> updateUser(User user, {String? jwtToken}) async {
    final url = Uri.parse('$baseUrl/utilisateur/${user.id}');
    final Map<String, dynamic> body = Map<String, dynamic>.from(user.toJson());
    body.remove("id");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        if (jwtToken != null) "Authorization": "Bearer $jwtToken",
      },
      body: utf8.encode(jsonEncode(body)),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la modification de l’utilisateur");
    }
  }

  // 🔹 Supprime un utilisateur
  Future<void> deleteUser(String id, {String? jwtToken}) async {
    final url = Uri.parse('$baseUrl/utilisateur/$id');

    final response = await http.delete(
      url,
      headers: {if (jwtToken != null) "Authorization": "Bearer $jwtToken"},
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de l’utilisateur");
    }
  }

  // 🔹 Récupère les chauffeurs d’une entreprise
  Future<List<User>> getChauffeursByEntreprise(
    String entrepriseId, {
    String? jwtToken,
  }) async {
    final url = Uri.parse('$baseUrl/utilisateurs/chauffeurs/$entrepriseId');

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        if (jwtToken != null) "Authorization": "Bearer $jwtToken",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception("Erreur lors de la récupération des chauffeurs");
    }
  }
}
