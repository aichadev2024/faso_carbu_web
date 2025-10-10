import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ticket.dart';
import '../services/api_service.dart';

class TicketService {
  final String baseUrl = "https://faso-carbu-backend-2.onrender.com/api";

  Future<List<Ticket>> getTickets() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString("role");
    final token = await ApiService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("⚠️ Aucun token JWT trouvé !");
    }

    String endpoint;
    if (role == "ROLE_DEMANDEUR") {
      endpoint = "/tickets/mes-tickets";
    } else if (role == "ROLE_GESTIONNAIRE") {
      endpoint = "/tickets/tous";
    } else {
      throw Exception("⚠️ Rôle non supporté: $role");
    }

    final response = await http.get(
      Uri.parse("$baseUrl$endpoint"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json; charset=UTF-8",
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Ticket.fromJson(json)).toList();
    } else {
      throw Exception("❌ Erreur chargement tickets: ${response.body}");
    }
  }

  Future<void> attribuerTicket(int ticketId, String chauffeurId) async {
    final token = await ApiService.getToken();
    final url = Uri.parse('$baseUrl/tickets/attribuer/$ticketId/$chauffeurId');

    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json; charset=UTF-8",
      },
    );

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 403) {
      throw Exception(
        "⛔ Vous n’avez pas l’autorisation d’attribuer un ticket (seul un gestionnaire peut le faire).",
      );
    } else if (response.statusCode == 404) {
      throw Exception("❌ Ticket ou chauffeur introuvable.");
    } else {
      throw Exception(
        "Erreur lors de l’attribution du ticket : ${response.body}",
      );
    }
  }
}
