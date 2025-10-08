import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demande_provider.dart';
import '../providers/user_provider.dart'; // 🔹 Pour charger les chauffeurs
import '../services/api_service.dart';
import 'demande_form_screen.dart';

class DemandeListScreen extends StatelessWidget {
  const DemandeListScreen({super.key});

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'VALIDEE':
        return Colors.green;
      case 'REJETEE':
        return Colors.red;
      default:
        return Colors.orange; // EN_ATTENTE
    }
  }

  String _getStatusLabel(String statut) {
    switch (statut) {
      case 'VALIDEE':
        return "Validée";
      case 'REJETEE':
        return "Rejetée";
      default:
        return "En attente";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "📋 Liste des demandes",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Consumer<DemandeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.demandes.isEmpty) {
            return const Center(
              child: Text(
                "Aucune demande pour le moment.\nCréez-en une nouvelle en appuyant sur +",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            );
          }

          return Column(
            children: [
              // ✅ Header résumé
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: Colors.indigo,
                child: Text(
                  "Total demandes : ${provider.demandes.length}",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // ✅ Liste des demandes
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.demandes.length,
                  itemBuilder: (context, index) {
                    final demande = provider.demandes[index];

                    final nomComplet =
                        (demande.demandeurNom != null &&
                            demande.demandeurNom!.isNotEmpty)
                        ? "${demande.demandeurPrenom ?? ''} ${demande.demandeurNom}"
                        : "${demande.gestionnairePrenom ?? ''} ${demande.gestionnaireNom ?? ''}";

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(demande.statut),
                          radius: 24,
                          child: Text(
                            (nomComplet.trim().isNotEmpty)
                                ? nomComplet[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          "$nomComplet souhaite ${demande.quantite} L de ${demande.carburantNom}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("⛽ Station : ${demande.stationNom}"),
                              Text(
                                "🚗 Véhicule : ${demande.vehiculeImmatriculation}",
                              ),
                              const SizedBox(height: 6),
                              Chip(
                                label: Text(
                                  _getStatusLabel(demande.statut),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(
                                  demande.statut,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            // ✅ Bouton Valider avec choix du chauffeur
                            IconButton(
                              icon: const Icon(Icons.check_circle),
                              color: Colors.green,
                              tooltip: "Valider",
                              onPressed: () async {
                                final token = await ApiService.getToken();
                                if (token == null) return;

                                // Charger les chauffeurs
                                final chauffeurs =
                                    await Provider.of<UserProvider>(
                                      context,
                                      listen: false,
                                    ).loadChauffeursByEntreprise(
                                      demande.entrepriseId!,
                                    );

                                String? selectedChauffeurId;

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text(
                                        "Attribuer à un chauffeur",
                                      ),
                                      content: StatefulBuilder(
                                        builder: (context, setState) {
                                          return DropdownButton<String>(
                                            isExpanded: true,
                                            value: selectedChauffeurId,
                                            hint: const Text(
                                              "Sélectionnez un chauffeur",
                                            ),
                                            items: chauffeurs.map((c) {
                                              return DropdownMenuItem(
                                                value: c.id,
                                                child: Text(
                                                  "${c.prenom} ${c.nom}",
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                selectedChauffeurId = value;
                                              });
                                            },
                                          );
                                        },
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Annuler"),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            if (selectedChauffeurId != null) {
                                              await provider.validateDemande(
                                                demande.id,
                                                selectedChauffeurId!,
                                                token,
                                              );
                                              if (context.mounted)
                                                Navigator.pop(context);
                                            }
                                          },
                                          child: const Text("Confirmer"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),

                            // ❌ Bouton Rejeter
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              tooltip: "Rejeter",
                              onPressed: () {
                                final motifController = TextEditingController();

                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      title: const Text("Rejeter la demande"),
                                      content: TextField(
                                        controller: motifController,
                                        decoration: const InputDecoration(
                                          labelText: "Motif du rejet",
                                          border: OutlineInputBorder(),
                                        ),
                                        maxLines: 3,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("Annuler"),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final token =
                                                await ApiService.getToken();
                                            if (token != null) {
                                              final motif =
                                                  motifController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? "Rejeté par le gestionnaire"
                                                  : motifController.text.trim();

                                              await provider.rejectDemande(
                                                demande.id,
                                                token,
                                                motif: motif,
                                              );

                                              if (context.mounted) {
                                                Navigator.pop(context);
                                              }
                                            }
                                          },
                                          child: const Text("Confirmer"),
                                        ),
                                      ],
                                    );
                                  },
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DemandeFormScreen()),
          );
        },
        label: const Text("Nouvelle demande"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
    );
  }
}
