import 'role.dart';
import 'entreprise.dart';

class User {
  String? id;
  String nom;
  String prenom;
  String email;
  String telephone;
  Role role;
  bool actif;
  Entreprise? entreprise; // ✅ nouvel attribut

  User({
    this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.role,
    this.actif = true,
    this.entreprise,
  });

  String roleToString() => role.name;

  static Role roleFromString(String value) {
    return Role.values.firstWhere(
      (r) => r.name.toUpperCase() == value.toUpperCase(),
      orElse: () => Role.DEMANDEUR,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: roleFromString(json['role'] ?? 'DEMANDEUR'),
      actif: json['actif'] ?? true,
      entreprise: json['entreprise'] != null
          ? Entreprise.fromJson(json['entreprise'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = {
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': roleToString(),
      'actif': actif,
      if (entreprise != null) 'entreprise': entreprise!.toJson(),
    };
    if (id != null && id!.isNotEmpty) {
      map['id'] = id!;
    }
    return map;
  }
}
