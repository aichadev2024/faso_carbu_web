import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/station.dart';
import '../dtos/station_avec_admin_request.dart';

class StationService {
  static const String _baseUrl =
      'https://faso-carbu-backend-2.onrender.com/api/gestionnaires';

  Future<List<Station>> getAllStations({required String jwtToken}) async {
    final uri = Uri.parse('$_baseUrl/stations');

    final res = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $jwtToken",
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(res.bodyBytes));
      return data.map((e) => Station.fromJson(e)).toList();
    } else {
      throw Exception(
        'Erreur chargement stations: ${res.statusCode} ${res.body}',
      );
    }
  }

  Future<Station> creerStationAvecAdmin(
    StationAvecAdminRequest request, {
    required String jwtToken,
  }) async {
    final uri = Uri.parse('$_baseUrl/stations');
    final body = utf8.encode(jsonEncode(request.toJson()));

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $jwtToken",
      },
      body: body,
    );

    if (res.statusCode == 201) {
      return Station.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    } else {
      throw Exception('Erreur création station: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> deleteStation(String id, {required String jwtToken}) async {
    final uri = Uri.parse('$_baseUrl/stations/$id');

    final res = await http.delete(
      uri,
      headers: {
        "Content-Type": "application/json; charset=UTF-8",
        "Authorization": "Bearer $jwtToken",
      },
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception(
        'Erreur suppression station: ${res.statusCode} ${res.body}',
      );
    }
  }
}
