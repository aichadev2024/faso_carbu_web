import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  final String baseUrl;

  DashboardService({required this.baseUrl});

  Future<int> getUserCount(String jwtToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/utilisateurs'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data as List).length;
    } else {
      throw Exception('Erreur récupération utilisateurs');
    }
  }

  Future<int> getStationCount(String jwtToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/gestionnaires/stations'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data as List).length;
    } else {
      throw Exception('Erreur récupération stations');
    }
  }

  Future<int> getVehiculeCount(String jwtToken) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/vehicules'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return (data as List).length;
    } else {
      throw Exception('Erreur récupération véhicules');
    }
  }
}
