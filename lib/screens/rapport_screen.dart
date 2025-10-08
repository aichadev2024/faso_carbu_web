// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../services/rapport_service.dart';

class RapportScreen extends StatefulWidget {
  final RapportService service;

  const RapportScreen({super.key, required this.service});

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  List<dynamic> tickets = [];
  bool loading = false;

  Future<void> chargerTickets(String chauffeurId) async {
    setState(() => loading = true);
    try {
      final result = await widget.service.getTicketsParChauffeur(chauffeurId);
      setState(() => tickets = result);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  void _downloadBytes(List<int> bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType); // ✅ Dart list OK with dart:html
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = filename
      ..click(); // no unused variable warning
    html.Url.revokeObjectUrl(url);
  }

  Future<void> exporterPDF() async {
    try {
      final response = await widget.service.exporterRapportPDF();
      _downloadBytes(
        response.bodyBytes.toList(),
        "rapport.pdf",
        "application/pdf",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rapport PDF exporté ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur export PDF: $e")));
    }
  }

  Future<void> exporterExcel() async {
    try {
      final response = await widget.service.exporterRapportExcel();
      _downloadBytes(
        response.bodyBytes.toList(),
        "rapport.xlsx",
        "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rapport Excel exporté ✅")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erreur export Excel: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rapport Tickets Chauffeur")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tickets.isEmpty
          ? const Center(child: Text("Aucun ticket"))
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("ID")),
                  DataColumn(label: Text("Station")),
                  DataColumn(label: Text("Montant")),
                  DataColumn(label: Text("Quantité")),
                  DataColumn(label: Text("Date Émission")),
                  DataColumn(label: Text("Statut")),
                ],
                rows: tickets.map((t) {
                  return DataRow(
                    cells: [
                      DataCell(Text("${t['id']}")),
                      DataCell(Text("${t['stationNom'] ?? '-'}")),
                      DataCell(Text("${t['montant']}")),
                      DataCell(Text("${t['quantite']}")),
                      DataCell(Text("${t['dateEmission']}")),
                      DataCell(Text("${t['statut']}")),
                    ],
                  );
                }).toList(),
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: "pdf",
            onPressed: exporterPDF,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text("PDF"),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: "excel",
            onPressed: exporterExcel,
            icon: const Icon(Icons.grid_on),
            label: const Text("Excel"),
          ),
        ],
      ),
    );
  }
}
