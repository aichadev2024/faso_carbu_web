import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ConsommationFormScreen extends StatefulWidget {
  @override
  _ConsommationFormScreenState createState() => _ConsommationFormScreenState();
}

class _ConsommationFormScreenState extends State<ConsommationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  List<dynamic> attributions = [];
  List<dynamic> carburants = [];
  String? selectedAttribution;
  String? selectedCarburant;
  TextEditingController quantiteCtrl = TextEditingController();
  TextEditingController commentaireCtrl = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final resAttr = await http.get(
      Uri.parse("https://faso-carbu-backend-2.onrender.com/api/attributions"),
      headers: {"Authorization": "Bearer $token"},
    );

    final resCarb = await http.get(
      Uri.parse("https://faso-carbu-backend-2.onrender.com/api/carburants"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (resAttr.statusCode == 200 && resCarb.statusCode == 200) {
      setState(() {
        attributions = jsonDecode(resAttr.body);
        carburants = jsonDecode(resCarb.body);
      });
    }
  }

  Future<void> saveConsommation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final body = jsonEncode({
      "attributionId": selectedAttribution,
      "carburantId": selectedCarburant,
      "quantiteUtilisee": double.parse(quantiteCtrl.text),
      "commentaire": commentaireCtrl.text,
    });

    final res = await http.post(
      Uri.parse("https://faso-carbu-backend-2.onrender.com/api/consommations"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: body,
    );

    setState(() => isLoading = false);

    if (res.statusCode == 201 || res.statusCode == 200) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de l'enregistrement")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Ajouter une consommation")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField(
                value: selectedAttribution,
                items: attributions.map<DropdownMenuItem<String>>((attr) {
                  return DropdownMenuItem(
                    value: attr['id'].toString(),
                    child: Text("Attribution: ${attr['id']}"),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedAttribution = val),
                decoration: InputDecoration(labelText: "Attribution"),
                validator: (v) =>
                    v == null ? "Sélectionner une attribution" : null,
              ),
              DropdownButtonFormField(
                value: selectedCarburant,
                items: carburants.map<DropdownMenuItem<String>>((carb) {
                  return DropdownMenuItem(
                    value: carb['id'].toString(),
                    child: Text(carb['type']),
                  );
                }).toList(),
                onChanged: (val) => setState(() => selectedCarburant = val),
                decoration: InputDecoration(labelText: "Carburant"),
                validator: (v) =>
                    v == null ? "Sélectionner un carburant" : null,
              ),
              TextFormField(
                controller: quantiteCtrl,
                decoration: InputDecoration(labelText: "Quantité utilisée (L)"),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Quantité requise" : null,
              ),
              TextFormField(
                controller: commentaireCtrl,
                decoration: InputDecoration(
                  labelText: "Commentaire (optionnel)",
                ),
              ),
              SizedBox(height: 20),
              isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: saveConsommation,
                      child: Text("Enregistrer"),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
