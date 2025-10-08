import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demande_provider.dart';
import '../providers/user_provider.dart';
import '../providers/station_provider.dart';
import '../providers/vehicule_provider.dart';
import '../providers/carburant_provider.dart';
import '../services/api_service.dart';

class DemandeFormScreen extends StatefulWidget {
  const DemandeFormScreen({super.key});

  @override
  State<DemandeFormScreen> createState() => _DemandeFormScreenState();
}

class _DemandeFormScreenState extends State<DemandeFormScreen> {
  String? selectedCarburant;
  String? selectedStation;
  String? selectedVehicule;
  double quantite = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await ApiService.getToken();

      if (context.mounted && token != null) {
        // Charger données initiales
        await Provider.of<UserProvider>(context, listen: false).loadUsers();
        await Provider.of<StationProvider>(
          context,
          listen: false,
        ).loadStations(jwtToken: token);
        await Provider.of<VehiculeProvider>(
          context,
          listen: false,
        ).loadVehicules(jwtToken: token);
        await Provider.of<CarburantProvider>(
          context,
          listen: false,
        ).loadCarburants(token);
        await Provider.of<DemandeProvider>(
          context,
          listen: false,
        ).fetchDemandes(token);
      }
    });
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.indigo),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.indigo, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final demandeProvider = Provider.of<DemandeProvider>(context);
    final stationProvider = Provider.of<StationProvider>(context);
    final vehiculeProvider = Provider.of<VehiculeProvider>(context);
    final carburantProvider = Provider.of<CarburantProvider>(context);

    if (userProvider.loading ||
        stationProvider.loading ||
        vehiculeProvider.loading ||
        carburantProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Nouvelle Demande",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.indigo),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  "Remplissez les informations pour créer une demande",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // 🔹 Carburant
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    "Carburant",
                    Icons.local_gas_station,
                  ),
                  items: carburantProvider.carburants
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c.id.toString(),
                          child: Text(c.nom),
                        ),
                      )
                      .toList(),
                  value: selectedCarburant,
                  onChanged: (val) => setState(() => selectedCarburant = val),
                ),
                const SizedBox(height: 16),

                // 🔹 Station
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration("Station", Icons.location_on),
                  items: stationProvider.stations
                      .map(
                        (s) => DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.nom),
                        ),
                      )
                      .toList(),
                  value: selectedStation,
                  onChanged: (val) => setState(() => selectedStation = val),
                ),
                const SizedBox(height: 16),

                // 🔹 Véhicule
                DropdownButtonFormField<String>(
                  decoration: _inputDecoration(
                    "Véhicule",
                    Icons.directions_car,
                  ),
                  items: vehiculeProvider.vehicules
                      .map(
                        (v) => DropdownMenuItem<String>(
                          value: v.id,
                          child: Text(
                            "${v.marque} ${v.modele} (${v.immatriculation})",
                          ),
                        ),
                      )
                      .toList(),
                  value: selectedVehicule,
                  onChanged: (val) => setState(() => selectedVehicule = val),
                ),

                const SizedBox(height: 16),

                // 🔹 Quantité
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    "Quantité (L)",
                    Icons.local_drink,
                  ),
                  onChanged: (val) =>
                      setState(() => quantite = double.tryParse(val) ?? 0),
                ),
                const SizedBox(height: 28),

                // 🔹 Bouton Créer
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Créer la demande",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 6, 7, 8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () async {
                      try {
                        final token = await ApiService.getToken();

                        if (selectedCarburant != null &&
                            selectedStation != null &&
                            selectedVehicule != null &&
                            quantite > 0 &&
                            token != null) {
                          await demandeProvider.createDemande(
                            carburantId: int.parse(selectedCarburant!),
                            stationId: int.parse(selectedStation!),
                            vehiculeId: int.parse(selectedVehicule!),
                            quantite: quantite,
                            jwtToken: token,
                          );

                          if (context.mounted) Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Veuillez remplir tous les champs"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Erreur : $e"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
