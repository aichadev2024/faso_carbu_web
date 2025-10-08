import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import '../dtos/station_avec_admin_request.dart';

class StationService {
  static const String _baseUrl =
      'https://faso-carbu-backend-2.onrender.com/api/gestionnaires';

  // =================== STATIONS CRUD ===================

  // Récupérer toutes les stations
  Future<List<Station>> getAllStations({required String jwtToken}) async {
    final uri = Uri.parse('$_baseUrl/stations');

    print("📡 GET $uri");
    print("🔑 Token: $jwtToken");

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwtToken",
      },
    );

    print("📥 Status: ${res.statusCode}");
    print("📥 Body: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Station.fromJson(e)).toList();
    } else {
      throw Exception(
        'Erreur chargement stations: ${res.statusCode} ${res.body}',
      );
    }
  }

  // Créer une station avec admin
  Future<Station> creerStationAvecAdmin(
    StationAvecAdminRequest request, {
    required String jwtToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/stations');

    final body = jsonEncode(request.toJson());

    print("📡 POST $uri");
    print("🔑 Token: $jwtToken");
    print("📤 Body envoyé: $body");

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwtToken",
      },
      body: body,
    );

    print("📥 Status: ${res.statusCode}");
    print("📥 Response: ${res.body}");

    if (res.statusCode == 201) {
      return Station.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Erreur création station: ${res.statusCode} ${res.body}');
    }
  }

  // Supprimer une station
  Future<void> deleteStation(String id, {required String jwtToken}) async {
    final uri = Uri.parse('$_baseUrl/stations/$id');

    print("📡 DELETE $uri");
    print("🔑 Token: $jwtToken");

    final res = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $jwtToken",
      },
    );

    print("📥 Status: ${res.statusCode}");
    print("📥 Response: ${res.body}");

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Erreur suppression station: ${res.statusCode} ${res.body}',
      );
    }
  }
}
