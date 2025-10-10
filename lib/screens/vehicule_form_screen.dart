import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../dtos/vehicule_request.dart';
import '../models/carburant.dart';
import '../providers/vehicule_provider.dart';

// ✅ Définition de la couleur vert pétrole
const vertPetrole = Color(0xFF006A6A);

class VehiculeFormScreen extends StatefulWidget {
  final String? id;
  final VehiculeRequest? vehiculeRequest;
  final String jwtToken;

  const VehiculeFormScreen({
    super.key,
    this.id,
    this.vehiculeRequest,
    required this.jwtToken,
  });

  @override
  State<VehiculeFormScreen> createState() => _VehiculeFormScreenState();
}

class _VehiculeFormScreenState extends State<VehiculeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _immatriculationController = TextEditingController();
  final _marqueController = TextEditingController();
  final _modeleController = TextEditingController();
  final _quotaController = TextEditingController();

  Carburant? selectedCarburant;
  List<Carburant> carburants = [];

  @override
  void initState() {
    super.initState();
    loadCarburants();

    if (widget.vehiculeRequest != null) {
      _immatriculationController.text = widget.vehiculeRequest!.immatriculation;
      _marqueController.text = widget.vehiculeRequest!.marque;
      _modeleController.text = widget.vehiculeRequest!.modele;
      _quotaController.text = widget.vehiculeRequest!.quotaCarburant.toString();

      selectedCarburant = Carburant(
        id: int.parse(widget.vehiculeRequest!.carburantId),
        nom: "",
        prix: 0,
      );
    }
  }

  Future<void> loadCarburants() async {
    final service = CarburantService();
    final list = await service.getAllCarburants(jwtToken: widget.jwtToken);
    setState(() {
      carburants = list;
      if (selectedCarburant != null) {
        selectedCarburant = carburants.firstWhere(
          (c) => c.id == selectedCarburant!.id,
          orElse: () => carburants.first,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vehiculeProvider = Provider.of<VehiculeProvider>(
      context,
      listen: false,
    );

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          widget.id == null ? "Ajouter un véhicule" : "Modifier le véhicule",
        ),
        centerTitle: true,
        backgroundColor: vertPetrole,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  spreadRadius: 3,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "✨ Remplissez ce formulaire pour gérer vos véhicules facilement !",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        _immatriculationController,
                        "Immatriculation",
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(_marqueController, "Marque"),
                      const SizedBox(height: 12),
                      _buildTextField(_modeleController, "Modèle"),
                      const SizedBox(height: 12),
                      _buildTextField(
                        _quotaController,
                        "Quota Carburant",
                        isNumber: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<Carburant>(
                        value: selectedCarburant,
                        items: carburants
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.nom),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCarburant = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: "Carburant",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) =>
                            v == null ? "Sélectionnez un carburant" : null,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: vertPetrole,
                          ),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final vehiculeRequest = VehiculeRequest(
                                immatriculation:
                                    _immatriculationController.text,
                                marque: _marqueController.text,
                                modele: _modeleController.text,
                                quotaCarburant:
                                    double.tryParse(_quotaController.text) ?? 0,
                                carburantId: selectedCarburant!.id.toString(),
                                userId: "1",
                              );

                              if (widget.id == null) {
                                vehiculeProvider.addVehicule(
                                  vehiculeRequest,
                                  jwtToken: widget.jwtToken,
                                );
                              } else {
                                vehiculeProvider.editVehicule(
                                  widget.id!,
                                  vehiculeRequest,
                                  jwtToken: widget.jwtToken,
                                );
                              }

                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            widget.id == null ? "Enregistrer" : "Mettre à jour",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (v) => v!.isEmpty ? "Champ obligatoire" : null,
    );
  }
}
