import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/vehicule_provider.dart';
import '../dtos/vehicule_request.dart';
import 'vehicule_form_screen.dart';

// ✅ Vert pétrole
const vertPetrole = Color(0xFF006A6A);

class VehiculeListScreen extends StatefulWidget {
  final String jwtToken;
  const VehiculeListScreen({super.key, required this.jwtToken});

  @override
  State<VehiculeListScreen> createState() => _VehiculeListScreenState();
}

class _VehiculeListScreenState extends State<VehiculeListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<VehiculeProvider>(
        context,
        listen: false,
      ).loadVehicules(jwtToken: widget.jwtToken);
    });
  }

  VehiculeRequest vehiculeToRequest(dynamic vehicule) {
    return VehiculeRequest(
      immatriculation: vehicule.immatriculation,
      marque: vehicule.marque,
      modele: vehicule.modele,
      quotaCarburant: vehicule.quotaCarburant,
      carburantId: vehicule.carburantId,
      userId: vehicule.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<VehiculeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Mes véhicules"),
        centerTitle: true,
        backgroundColor: vertPetrole,
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    "🚗 Bienvenue sur votre tableau de bord véhicules ! Gérer ou ajouter vos véhicules facilement ci-dessous.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: provider.vehicules.length,
                      itemBuilder: (context, index) {
                        final vehicule = provider.vehicules[index];
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 16,
                            ),
                            title: Text(
                              vehicule.immatriculation,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              "${vehicule.marque} - ${vehicule.modele}",
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: vertPetrole,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => VehiculeFormScreen(
                                          id: vehicule.id,
                                          vehiculeRequest: vehiculeToRequest(
                                            vehicule,
                                          ),
                                          jwtToken: widget.jwtToken,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    provider.removeVehicule(
                                      vehicule.id,
                                      jwtToken: widget.jwtToken,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VehiculeFormScreen(jwtToken: widget.jwtToken),
            ),
          );
        },
        backgroundColor: vertPetrole,
        child: const Icon(Icons.add),
      ),
    );
  }
}
