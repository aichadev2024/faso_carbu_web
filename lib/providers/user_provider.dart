import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  final _service = UserService();

  List<User> _users = [];
  List<User> get users => _users;

  bool _loading = false;
  bool get loading => _loading;

  String _search = '';
  String get search => _search;

  // 🔹 Nouvel attribut pour l’utilisateur connecté
  User? _currentUser;
  User? get currentUser => _currentUser;

  // ================= CHARGER UTILISATEURS =================
  Future<void> loadUsers({String search = ''}) async {
    _loading = true;
    _search = search;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      _users = await _service.getAllUsers(search: search, jwtToken: token);
    } catch (_) {
      _users = [];
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ================= RÉCUPÉRER L’UTILISATEUR CONNECTÉ =================
  Future<void> loadCurrentUser() async {
    _loading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token != null) {
        _currentUser = await _service.getCurrentUser(jwtToken: token);
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ================= CRUD =================
  Future<void> addUser({required User user, required String motDePasse}) async {
    _loading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      final newUser = await _service.createUser(
        user: user,
        motDePasse: motDePasse,
        jwtToken: token,
      );
      _users.add(newUser);
      notifyListeners();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> registerGestionnaire({
    required User user,
    required String motDePasse,
    required String nomEntreprise,
    required String adresseEntreprise,
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      return await _service.registerGestionnaire(
        user: user,
        motDePasse: motDePasse,
        nomEntreprise: nomEntreprise,
        adresseEntreprise: adresseEntreprise,
        jwtToken: token,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> editUser(User user) async {
    _loading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      await _service.updateUser(user, jwtToken: token);
      await loadUsers(search: _search);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> removeUser(String id) async {
    _loading = true;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      await _service.deleteUser(id, jwtToken: token);
      _users.removeWhere((u) => u.id == id);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<List<User>> loadChauffeursByEntreprise(String entrepriseId) async {
    final token = await ApiService.getToken();
    return await _service.getChauffeursByEntreprise(
      entrepriseId,
      jwtToken: token,
    );
  }
}
