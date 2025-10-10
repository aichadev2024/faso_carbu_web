import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/demande.dart';

class DemandeService {
  final String baseUrl = "https://faso-carbu-backend-2.onrender.com";

  // ===================== Récupérer toutes les demandes =====================
  Future<List<Demande>> getAllDemandes({required String jwtToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/demandes'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      print("✅ Réponse demandes: ${response.body}");
      // ✅ Forcer le décodage UTF-8 pour corriger les accents
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((d) => Demande.fromJson(d)).toList();
    } else {
      print("❌ Erreur HTTP: ${response.statusCode} - ${response.body}");
      throw Exception('Erreur récupération demandes: ${response.body}');
    }
  }

  // ===================== Créer une demande =====================
  Future<void> createDemande({
    required int carburantId,
    required int stationId,
    required int vehiculeId,
    required double quantite,
    required String jwtToken,
  }) async {
    final Map<String, dynamic> body = {
      "carburantId": carburantId,
      "stationId": stationId,
      "vehiculeId": vehiculeId,
      "quantite": quantite,
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/demandes'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8', // ✅ forcer UTF-8
        'Authorization': 'Bearer $jwtToken',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Impossible de créer la demande: ${response.body}');
    }
  }

  // ===================== Valider une demande =====================
  Future<void> validateDemande({
    required int demandeId,
    required String chauffeurId,
    required String jwtToken,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/gestionnaires/demandes/$demandeId/valider?chauffeurId=$chauffeurId',
    );

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors de la validation: ${response.body}');
    }
  }

  // ===================== Rejeter une demande =====================
  Future<void> rejectDemande({
    required int demandeId,
    required String jwtToken,
    String motif = "Demande rejetée par le gestionnaire",
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/gestionnaires/demandes/$demandeId/rejeter'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8', // ✅
      },
      body: jsonEncode({"motif": motif}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erreur lors du rejet: ${response.body}');
    }
  }
}
