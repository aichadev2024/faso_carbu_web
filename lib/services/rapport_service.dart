import 'dart:convert';
import 'package:http/http.dart' as http;

class RapportService {
  final String baseUrl;
  final String token;

  RapportService({required this.baseUrl, required this.token});

  Map<String, String> get _headers => {
    "Authorization": "Bearer $token",
    "Content-Type": "application/json",
  };

  /// ✅ Récupérer tickets d’un chauffeur
  Future<List<dynamic>> getTicketsParChauffeur(String chauffeurId) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/gestionnaires/rapport/tickets?chauffeurId=$chauffeurId',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur récupération tickets chauffeur");
    }
  }

  /// ✅ Récupérer tickets filtrés par période
  Future<List<dynamic>> getTicketsParChauffeurEtDates(
    String chauffeurId,
    DateTime dateDebut,
    DateTime dateFin,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/api/gestionnaires/rapport/tickets/filtre?chauffeurId=$chauffeurId&dateDebut=${dateDebut.toIso8601String()}&dateFin=${dateFin.toIso8601String()}',
      ),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur récupération tickets chauffeur avec filtre");
    }
  }

  /// ✅ Exporter rapport consommation en PDF
  Future<http.Response> exporterRapportPDF() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gestionnaires/rapport/consommation'),
      headers: {..._headers, "Accept": "application/pdf"},
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception("Erreur export PDF");
    }
  }

  /// ✅ Exporter rapport consommation en Excel
  Future<http.Response> exporterRapportExcel() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gestionnaires/rapport/consommation'),
      headers: {
        ..._headers,
        "Accept":
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      },
    );

    if (response.statusCode == 200) {
      return response;
    } else {
      throw Exception("Erreur export Excel");
    }
  }
}
