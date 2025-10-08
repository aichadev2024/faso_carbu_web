import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'consommation_form_screen.dart';

class ConsommationScreen extends StatefulWidget {
  @override
  _ConsommationScreenState createState() => _ConsommationScreenState();
}

class _ConsommationScreenState extends State<ConsommationScreen> {
  List<dynamic> consommations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchConsommations();
  }

  Future<void> fetchConsommations() async {
    setState(() => isLoading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final res = await http.get(
      Uri.parse("https://faso-carbu-backend-2.onrender.com/api/consommations"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      setState(() {
        consommations = jsonDecode(res.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors du chargement")));
    }
  }

  Future<void> deleteConsommation(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final res = await http.delete(
      Uri.parse(
        "https://faso-carbu-backend-2.onrender.com/api/consommations/$id",
      ),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      fetchConsommations();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Consommation supprimée")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur lors de la suppression")));
    }
  }

  void goToForm() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ConsommationFormScreen()),
    );
    fetchConsommations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Gestion des consommations")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : consommations.isEmpty
          ? Center(child: Text("Aucune consommation trouvée"))
          : ListView.builder(
              itemCount: consommations.length,
              itemBuilder: (context, index) {
                final c = consommations[index];
                return Card(
                  child: ListTile(
                    title: Text("Quantité : ${c['quantiteUtilisee']} L"),
                    subtitle: Text(
                      "Date : ${c['dateConsommation']} \nCommentaire : ${c['commentaire'] ?? 'Aucun'}",
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => deleteConsommation(c['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: goToForm,
        child: Icon(Icons.add),
      ),
    );
  }
}
