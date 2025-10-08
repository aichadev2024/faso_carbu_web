import 'package:flutter/material.dart';
import '../models/carburant.dart';

class CarburantProvider extends ChangeNotifier {
  final CarburantService _service = CarburantService();

  List<Carburant> _carburants = [];
  bool _loading = false;

  List<Carburant> get carburants => _carburants;
  bool get loading => _loading;

  Future<void> loadCarburants(String jwtToken) async {
    _loading = true;
    notifyListeners();

    try {
      _carburants = await _service.getAllCarburants(jwtToken: jwtToken);
    } catch (e) {
      debugPrint("❌ Erreur chargement carburants: $e");
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
