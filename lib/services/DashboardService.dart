import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl;

  DashboardService({required this.baseUrl});

  // ===================== Compter les utilisateurs =====================
  Future<int> getUserCount(String jwtToken) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/utilisateurs'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("✅ [Dashboard] Requête utilisateurs => ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return (data as List).length;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        print("⚠️ [Dashboard] Accès refusé utilisateurs (${res.statusCode})");
        return 0;
      } else {
        throw Exception('Erreur récupération utilisateurs: ${res.body}');
      }
    } catch (e) {
      print("❌ Erreur getUserCount: $e");
      return 0;
    }
  }

  // ===================== Compter les stations =====================
  Future<int> getStationCount(String jwtToken) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/gestionnaires/stations'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("✅ [Dashboard] Requête stations => ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return (data as List).length;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        print("⚠️ [Dashboard] Accès refusé stations (${res.statusCode})");
        return 0;
      } else {
        throw Exception('Erreur récupération stations: ${res.body}');
      }
    } catch (e) {
      print("❌ Erreur getStationCount: $e");
      return 0;
    }
  }

  // ===================== Compter les véhicules =====================
  Future<int> getVehiculeCount(String jwtToken) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/api/vehicules'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      print("✅ [Dashboard] Requête véhicules => ${res.statusCode}");

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        return (data as List).length;
      } else if (res.statusCode == 401 || res.statusCode == 403) {
        print("⚠️ [Dashboard] Accès refusé véhicules (${res.statusCode})");
        return 0;
      } else {
        throw Exception('Erreur récupération véhicules: ${res.body}');
      }
    } catch (e) {
      print("❌ Erreur getVehiculeCount: $e");
      return 0;
    }
  }
}
