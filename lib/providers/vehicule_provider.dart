import 'package:flutter/material.dart';
import '../dtos/vehicule_request.dart';
import '../services/vehicule_service.dart';
import '../models/vehicule.dart';

class VehiculeProvider extends ChangeNotifier {
  final VehiculeService _service = VehiculeService();

  bool _loading = false;
  bool get loading => _loading;

  List<Vehicule> _vehicules = [];
  List<Vehicule> get vehicules => _vehicules;

  bool disposed = false;
  void _safeNotify() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  // ✅ Charger tous les véhicules depuis le backend avec jwtToken
  Future<void> loadVehicules({required String jwtToken}) async {
    _loading = true;
    _safeNotify();
    try {
      _vehicules = await _service.getAllVehicules(jwtToken: jwtToken);
    } catch (e) {
      debugPrint('Erreur chargement véhicules: $e');
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  // ✅ Ajouter un véhicule
  Future<void> addVehicule(
    VehiculeRequest vehiculeRequest, {
    required String jwtToken,
  }) async {
    _loading = true;
    _safeNotify();
    try {
      await _service.createVehicule(vehiculeRequest, jwtToken: jwtToken);
      await loadVehicules(jwtToken: jwtToken); // recharge la liste
    } catch (e) {
      debugPrint('Erreur ajout véhicule: $e');
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  // ✅ Modifier un véhicule
  Future<void> editVehicule(
    String id,
    VehiculeRequest vehiculeRequest, {
    required String jwtToken,
  }) async {
    _loading = true;
    _safeNotify();
    try {
      await _service.updateVehicule(id, vehiculeRequest, jwtToken: jwtToken);
      await loadVehicules(jwtToken: jwtToken); // recharge la liste
    } catch (e) {
      debugPrint('Erreur mise à jour véhicule: $e');
    } finally {
      _loading = false;
      _safeNotify();
    }
  }

  // ✅ Supprimer un véhicule
  Future<void> removeVehicule(String id, {required String jwtToken}) async {
    _loading = true;
    _safeNotify();
    try {
      await _service.deleteVehicule(id, jwtToken: jwtToken);
      _vehicules.removeWhere((v) => v.id == id); // supprime localement
      _safeNotify();
    } catch (e) {
      debugPrint('Erreur suppression véhicule: $e');
    } finally {
      _loading = false;
      _safeNotify();
    }
  }
}
