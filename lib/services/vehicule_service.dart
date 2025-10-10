import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vehicule.dart';
import '../dtos/vehicule_request.dart';

class VehiculeService {
  static const String _baseUrl =
      'https://faso-carbu-backend-2.onrender.com/api';

  Future<List<Vehicule>> getAllVehicules({required String jwtToken}) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/vehicules'),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $jwtToken",
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((json) => Vehicule.fromJson(json)).toList();
    } else {
      throw Exception(
        'Erreur récupération véhicules: ${res.statusCode} - ${res.body}',
      );
    }
  }

  Future<void> createVehicule(
    VehiculeRequest v, {
    required String jwtToken,
  }) async {
    final body = utf8.encode(jsonEncode(v.toJson()));

    final res = await http.post(
      Uri.parse('$_baseUrl/vehicules/ajouter'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $jwtToken',
      },
      body: body,
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        'Erreur création véhicule: ${res.statusCode} - ${res.body}',
      );
    }
  }

  Future<void> updateVehicule(
    String id,
    VehiculeRequest v, {
    required String jwtToken,
  }) async {
    final body = utf8.encode(jsonEncode(v.toJson()));

    final res = await http.put(
      Uri.parse('$_baseUrl/vehicules/$id'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $jwtToken',
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Erreur mise à jour véhicule: ${res.statusCode} - ${res.body}',
      );
    }
  }

  Future<void> deleteVehicule(String id, {required String jwtToken}) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/vehicules/$id'),
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $jwtToken",
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Erreur suppression véhicule: ${res.statusCode} - ${res.body}',
      );
    }
  }
}
