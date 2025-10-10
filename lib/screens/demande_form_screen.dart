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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final token = await ApiService.getToken();
    if (!mounted || token == null) return;

    setState(() => isLoading = true);

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

    if (mounted) setState(() => isLoading = false);
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF07575B)),
      filled: true,
      fillColor: Colors.grey.shade100,
      labelStyle: const TextStyle(color: Color(0xFF003B46)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0E9AA7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF07575B), width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final stationProvider = Provider.of<StationProvider>(context);
    final vehiculeProvider = Provider.of<VehiculeProvider>(context);
    final carburantProvider = Provider.of<CarburantProvider>(context);
    final demandeProvider = Provider.of<DemandeProvider>(context);

    if (isLoading ||
        userProvider.loading ||
        stationProvider.loading ||
        vehiculeProvider.loading ||
        carburantProvider.loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0E9AA7)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E9AA7),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Nouvelle Demande",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
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
                    color: Color(0xFF003B46),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Carburant
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF003B46)),
                  decoration: _inputDecoration(
                    "Carburant",
                    Icons.local_gas_station,
                  ),
                  items: carburantProvider.carburants
                      .map(
                        (c) => DropdownMenuItem(
                          value: c.id.toString(),
                          child: Text(c.nom),
                        ),
                      )
                      .toList(),
                  value: selectedCarburant,
                  onChanged: (val) => setState(() => selectedCarburant = val),
                ),
                const SizedBox(height: 16),

                // Station
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF003B46)),
                  decoration: _inputDecoration("Station", Icons.location_on),
                  items: stationProvider.stations
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.nom)),
                      )
                      .toList(),
                  value: selectedStation,
                  onChanged: (val) => setState(() => selectedStation = val),
                ),
                const SizedBox(height: 16),

                // Véhicule
                DropdownButtonFormField<String>(
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF003B46)),
                  decoration: _inputDecoration(
                    "Véhicule",
                    Icons.directions_car,
                  ),
                  items: vehiculeProvider.vehicules
                      .map(
                        (v) => DropdownMenuItem(
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

                // Quantité
                TextFormField(
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: Color(0xFF003B46)),
                  decoration: _inputDecoration(
                    "Quantité (L)",
                    Icons.local_drink,
                  ),
                  onChanged: (val) =>
                      setState(() => quantite = double.tryParse(val) ?? 0),
                ),
                const SizedBox(height: 28),

                // Bouton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    label: const Text(
                      "Créer la demande",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF07575B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () async {
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
                            backgroundColor: Color(0xFF0E9AA7),
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
