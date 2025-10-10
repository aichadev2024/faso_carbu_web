import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/demande_provider.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import 'demande_form_screen.dart';

class DemandeListScreen extends StatefulWidget {
  const DemandeListScreen({super.key});

  @override
  State<DemandeListScreen> createState() => _DemandeListScreenState();
}

class _DemandeListScreenState extends State<DemandeListScreen> {
  String? _jwtToken;

  @override
  void initState() {
    super.initState();
    _loadDemandes();
  }

  Future<void> _loadDemandes() async {
    final token = await ApiService.getToken();
    if (token == null) return;
    setState(() => _jwtToken = token);
    final provider = Provider.of<DemandeProvider>(context, listen: false);
    await provider.fetchDemandes(token);
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'VALIDEE':
        return const Color(0xFF0E9AA7);
      case 'REJETEE':
        return Colors.redAccent;
      default:
        return const Color(0xFF07575B);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0E9AA7),
        elevation: 2,
        centerTitle: true,
        title: const Text(
          "📋 Liste des demandes",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadDemandes,
          ),
        ],
      ),
      body: Consumer<DemandeProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF0E9AA7)),
            );
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Text(
                "Erreur : ${provider.errorMessage}",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (provider.demandes.isEmpty) {
            return const Center(
              child: Text(
                "Aucune demande pour le moment.\nCréez-en une nouvelle en appuyant sur +",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Color(0xFF003B46)),
              ),
            );
          }

          return RefreshIndicator(
            color: const Color(0xFF0E9AA7),
            onRefresh: _loadDemandes,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne d’en-tête
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: _getStatusColor(demande.statut),
                            child: Text(
                              nomComplet.isNotEmpty
                                  ? nomComplet[0].toUpperCase()
                                  : "?",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "$nomComplet souhaite ${demande.quantite} L de ${demande.carburantNom}",
                              style: const TextStyle(
                                color: Color(0xFF003B46),
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Chip(
                            label: Text(
                              _getStatusLabel(demande.statut),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: _getStatusColor(demande.statut),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(color: Colors.black12, thickness: 1),
                      const SizedBox(height: 8),

                      // Station et véhicule
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "⛽ Station : ${demande.stationNom}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "🚗 Véhicule : ${demande.vehiculeImmatriculation}",
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Boutons d’action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // ✅ Bouton VALIDER
                          IconButton(
                            tooltip: "Valider la demande",
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF0E9AA7),
                            ),
                            onPressed: _jwtToken == null
                                ? null
                                : () async {
                                    try {
                                      final userProvider =
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          );
                                      final chauffeurs = await userProvider
                                          .loadChauffeursByEntreprise(
                                            demande.entrepriseId!,
                                          );

                                      if (!context.mounted) return;

                                      String? selectedChauffeurId;

                                      showDialog(
                                        context: context,
                                        builder: (_) => StatefulBuilder(
                                          builder: (context, setState) {
                                            return AlertDialog(
                                              backgroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              title: const Text(
                                                "Attribuer un chauffeur",
                                                style: TextStyle(
                                                  color: Color(0xFF003B46),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              content: chauffeurs.isEmpty
                                                  ? const Text(
                                                      "Aucun chauffeur disponible pour cette entreprise.",
                                                      style: TextStyle(
                                                        color: Colors.redAccent,
                                                      ),
                                                    )
                                                  : DropdownButtonFormField<
                                                      String
                                                    >(
                                                      decoration:
                                                          const InputDecoration(
                                                            labelText:
                                                                "Chauffeur",
                                                            labelStyle:
                                                                TextStyle(
                                                                  color: Color(
                                                                    0xFF07575B,
                                                                  ),
                                                                ),
                                                            border:
                                                                OutlineInputBorder(),
                                                          ),
                                                      value:
                                                          selectedChauffeurId,
                                                      items: chauffeurs
                                                          .map(
                                                            (
                                                              c,
                                                            ) => DropdownMenuItem(
                                                              value: c.id,
                                                              child: Text(
                                                                "${c.prenom} ${c.nom}",
                                                              ),
                                                            ),
                                                          )
                                                          .toList(),
                                                      onChanged: (v) => setState(
                                                        () =>
                                                            selectedChauffeurId =
                                                                v,
                                                      ),
                                                    ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text(
                                                    "Annuler",
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                              0xFF0E9AA7,
                                                            ),
                                                      ),
                                                  onPressed:
                                                      selectedChauffeurId ==
                                                          null
                                                      ? null
                                                      : () async {
                                                          await provider
                                                              .validateDemande(
                                                                demande.id,
                                                                selectedChauffeurId!,
                                                                _jwtToken!,
                                                              );
                                                          if (context.mounted) {
                                                            Navigator.pop(
                                                              context,
                                                            );
                                                          }
                                                        },
                                                  child: const Text(
                                                    "Valider",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      );
                                    } catch (e) {
                                      debugPrint(
                                        "Erreur chargement chauffeurs : $e",
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "⚠️ Erreur lors du chargement des chauffeurs",
                                          ),
                                          backgroundColor: Colors.redAccent,
                                        ),
                                      );
                                    }
                                  },
                          ),

                          // ❌ Bouton REJETER
                          IconButton(
                            tooltip: "Rejeter la demande",
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: Colors.redAccent,
                            ),
                            onPressed: _jwtToken == null
                                ? null
                                : () async {
                                    TextEditingController motifController =
                                        TextEditingController();
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text(
                                          "Rejeter la demande",
                                          style: TextStyle(
                                            color: Color(0xFF003B46),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: TextField(
                                          controller: motifController,
                                          decoration: const InputDecoration(
                                            labelText: "Motif",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text(
                                              "Annuler",
                                              style: TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                            ),
                                            onPressed: () async {
                                              if (motifController
                                                  .text
                                                  .isNotEmpty) {
                                                await provider.rejectDemande(
                                                  demande.id,
                                                  _jwtToken!,
                                                  motif: motifController.text
                                                      .trim(),
                                                );
                                                if (context.mounted)
                                                  Navigator.pop(context);
                                              }
                                            },
                                            child: const Text(
                                              "Rejeter",
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
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
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Nouvelle demande"),
        backgroundColor: const Color(0xFF07575B),
      ),
    );
  }
}
