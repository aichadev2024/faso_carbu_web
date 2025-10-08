import 'package:flutter/foundation.dart';
import '../models/demande.dart';
import '../services/demande_service.dart';

class DemandeProvider with ChangeNotifier {
  final DemandeService _demandeService = DemandeService();

  List<Demande> _demandes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Demande> get demandes => _demandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDemandes(String jwtToken) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _demandes = await _demandeService.getAllDemandes(jwtToken: jwtToken);
      print("✅ Demandes chargées: ${_demandes.length}");
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===================== Créer une demande =====================
  Future<void> createDemande({
    required int carburantId,
    required int stationId,
    required int vehiculeId,
    required double quantite,
    required String jwtToken,
  }) async {
    try {
      await _demandeService.createDemande(
        carburantId: carburantId,
        stationId: stationId,
        vehiculeId: vehiculeId,
        quantite: quantite,
        jwtToken: jwtToken,
      );

      await fetchDemandes(jwtToken);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ===================== Valider une demande =====================
  // ===================== Valider une demande =====================
  Future<void> validateDemande(
    int demandeId,
    String chauffeurId, // 🚀 ajout
    String jwtToken,
  ) async {
    try {
      await _demandeService.validateDemande(
        demandeId: demandeId,
        chauffeurId: chauffeurId, // 🚀 passage au service
        jwtToken: jwtToken,
      );

      _demandes = _demandes.map((d) {
        if (d.id == demandeId) {
          return d.copyWith(statut: "VALIDEE");
        }
        return d;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ===================== Rejeter une demande =====================
  Future<void> rejectDemande(
    int demandeId,
    String jwtToken, {
    String motif = "Demande rejetée par le gestionnaire",
  }) async {
    try {
      await _demandeService.rejectDemande(
        demandeId: demandeId,
        jwtToken: jwtToken,
        motif: motif,
      );

      _demandes = _demandes.map((d) {
        if (d.id == demandeId) {
          return d.copyWith(statut: "REJETEE");
        }
        return d;
      }).toList();

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }
}
