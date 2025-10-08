import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'station_form_screen.dart';
import '../providers/station_provider.dart';

class StationListScreen extends StatefulWidget {
  final String jwtToken; // 👈 ajoute le token ici pour le passer au provider

  const StationListScreen({Key? key, required this.jwtToken}) : super(key: key);

  @override
  State<StationListScreen> createState() => _StationListScreenState();
}

class _StationListScreenState extends State<StationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stationProvider = Provider.of<StationProvider>(
        context,
        listen: false,
      );

      // ✅ plus de setJwtToken
      stationProvider.loadStations(jwtToken: widget.jwtToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stationProvider = Provider.of<StationProvider>(context);
    final stations = stationProvider.stations;
    final loading = stationProvider.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stations'),
        actions: [
          IconButton(
            tooltip: 'Ajouter Station',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StationFormScreen(
                    jwtToken: widget.jwtToken, // ✅ passage du token
                  ),
                ),
              );
              await stationProvider.loadStations(
                jwtToken: widget.jwtToken,
              ); // ✅ token obligatoire
            },
          ),
        ],
        backgroundColor: Colors.deepPurpleAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Message de bienvenue
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Bienvenue sur la page des stations ! Découvrez toutes vos stations actives et gérez-les facilement.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Liste ou loading
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : stations.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune station trouvée',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: stations.length,
                      itemBuilder: (context, index) {
                        final s = stations[index];
                        return Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            title: Text(
                              s.nom,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  '${s.adresse} - ${s.ville}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 6),
                                // Badge état actif
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.actif
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    s.actif ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () {
                                    // TODO: Écran édition station
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () async {
                                    try {
                                      await stationProvider.removeStation(
                                        s.id,
                                        jwtToken: widget
                                            .jwtToken, // ✅ token obligatoire
                                      );

                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Station supprimée'),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text('Erreur: $e')),
                                      );
                                    }
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
    );
  }
}
