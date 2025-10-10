import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/ticket.dart';
import '../models/user.dart';
import '../services/ticket_service.dart';
import '../providers/user_provider.dart';

// ✅ Couleur vert pétrole
const vertPetrole = Color(0xFF006A6A);

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TicketService ticketService = TicketService();
  late Future<List<Ticket>> _ticketsFuture;

  @override
  void initState() {
    super.initState();
    _ticketsFuture = _loadTickets();
  }

  Future<List<Ticket>> _loadTickets() async {
    return ticketService.getTickets();
  }

  Future<void> _attribuerTicket(BuildContext context, Ticket t) async {
    if (t.entrepriseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Impossible de récupérer l'entreprise depuis le ticket",
          ),
        ),
      );
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      final chauffeurs = await userProvider.loadChauffeursByEntreprise(
        t.entrepriseId.toString(),
      );

      if (chauffeurs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Aucun chauffeur disponible")),
        );
        return;
      }

      final chauffeur = await showDialog<User>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Attribuer à un chauffeur"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: chauffeurs
                  .map(
                    (c) => ListTile(
                      title: Text("${c.nom} ${c.prenom}"),
                      onTap: () => Navigator.pop(ctx, c),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      if (chauffeur != null) {
        await ticketService.attribuerTicket(t.id!, chauffeur.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Ticket attribué avec succès")),
        );

        setState(() {
          _ticketsFuture = _loadTickets();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur attribution : $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: vertPetrole.withOpacity(
        0.05,
      ), // 🌿 Fond léger vert pétrole
      appBar: AppBar(
        title: const Text("🎟️ Tickets Carburant"),
        centerTitle: true,
        backgroundColor: vertPetrole,
        elevation: 0,
      ),
      body: FutureBuilder<List<Ticket>>(
        future: _ticketsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: vertPetrole),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Oops! Une erreur est survenue : ${snapshot.error}",
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.airplane_ticket, size: 80, color: vertPetrole),
                  SizedBox(height: 16),
                  Text(
                    "Aucun ticket disponible pour le moment 😔",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Créez-en un nouveau pour attribuer à vos chauffeurs!",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final tickets = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final t = tickets[index];

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 🌈 Bandeau entreprise + statut
                    Container(
                      decoration: BoxDecoration(
                        color: vertPetrole,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "🏢 ${t.entrepriseNom ?? 'Entreprise'}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: (t.statut == "VALIDE")
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              t.statut ?? "-",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 📝 Infos principales
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${t.carburantNom ?? 'Carburant'} • ${t.quantite ?? 0} L",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: vertPetrole,
                            ),
                          ),
                          const Divider(),
                          Text(
                            "💰 Somme : ${t.somme?.toStringAsFixed(0) ?? '0'} FCFA",
                          ),
                          Text(
                            "👨 Chauffeur : ${t.utilisateurNom ?? '-'} ${t.utilisateurPrenom ?? ''}",
                          ),
                          Text(
                            "🛠 Validateur : ${t.validateurNom ?? '-'} ${t.validateurPrenom ?? ''}",
                          ),
                          Text(
                            "🚘 Véhicule : ${t.vehiculeImmatriculation ?? '-'}",
                          ),
                          Text("⛽ Station : ${t.stationNom ?? '-'}"),
                          Text(
                            "📅 Émis le : ${Ticket.formatDate(t.dateEmission)}",
                          ),
                          Text(
                            "✅ Validé le : ${Ticket.formatDate(t.dateValidation)}",
                          ),
                        ],
                      ),
                    ),

                    // 🔳 QR Code + Action
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: vertPetrole.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          (t.codeQr != null)
                              ? QrImageView(data: t.codeQr!, size: 90)
                              : const Icon(
                                  Icons.qr_code,
                                  color: vertPetrole,
                                  size: 40,
                                ),
                          if (t.utilisateurNom == null)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: vertPetrole,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              icon: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                              ),
                              label: const Text(
                                "Attribuer",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              onPressed: () => _attribuerTicket(context, t),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
