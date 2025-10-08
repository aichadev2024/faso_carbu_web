import 'package:flutter/material.dart';
import '../models/station.dart';
import '../dtos/station_avec_admin_request.dart';
import '../services/station_service.dart';

class StationProvider extends ChangeNotifier {
  final StationService _service = StationService();

  List<Station> _stations = [];
  bool _loading = false;

  List<Station> get stations => _stations;
  bool get loading => _loading;

  // Charger les stations
  Future<void> loadStations({required String jwtToken}) async {
    _loading = true;
    notifyListeners();

    try {
      _stations = await _service.getAllStations(jwtToken: jwtToken);
    } catch (e) {
      debugPrint('Erreur chargement stations: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Ajouter une station
  Future<void> addStation(
    StationAvecAdminRequest request, {
    required String jwtToken,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final station = await _service.creerStationAvecAdmin(
        request,
        jwtToken: jwtToken,
      );
      _stations.add(station);
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Supprimer une station
  Future<void> removeStation(String id, {required String jwtToken}) async {
    _loading = true;
    notifyListeners();

    try {
      await _service.deleteStation(id, jwtToken: jwtToken);
      _stations.removeWhere((s) => s.id == id);
    } catch (e) {
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
