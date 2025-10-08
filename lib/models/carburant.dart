import 'dart:convert';
import 'package:http/http.dart' as http;

class Carburant {
  final int id;
  final String nom;
  final double prix;

  Carburant({required this.id, required this.nom, required this.prix});

  factory Carburant.fromJson(Map<String, dynamic> json) {
    return Carburant(
      id: json['id'],
      nom: json['nom'],
      prix: (json['prix'] as num).toDouble(),
    );
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Carburant && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CarburantService {
  static const String _baseUrl =
      "https://faso-carbu-backend-2.onrender.com/api";

  // 🔹 Ajout du jwtToken en paramètre
  Future<List<Carburant>> getAllCarburants({required String jwtToken}) async {
    final res = await http.get(
      Uri.parse("$_baseUrl/carburants"),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Carburant.fromJson(e)).toList();
    } else {
      throw Exception("Erreur chargement carburants: ${res.statusCode}");
    }
  }
}
