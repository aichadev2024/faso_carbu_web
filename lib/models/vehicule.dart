import 'user.dart';

class Vehicule {
  final String id; // UUID backend
  final String immatriculation;
  final String marque;
  final String modele;
  final double quotaCarburant;

  // 🔹 Clés étrangères
  final String carburantId;
  final String carburantNom;
  final String utilisateurId;
  final String utilisateurNom;

  // 🔹 L'objet utilisateur complet (optionnel)
  final User? utilisateur;

  Vehicule({
    required this.id,
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.quotaCarburant,
    required this.carburantId,
    required this.carburantNom,
    required this.utilisateurId,
    required this.utilisateurNom,
    this.utilisateur,
  });

  factory Vehicule.fromJson(Map<String, dynamic> json) {
    return Vehicule(
      id: json['id']?.toString() ?? '',
      immatriculation: json['immatriculation'] ?? '',
      marque: json['marque'] ?? '',
      modele: json['modele'] ?? '',
      quotaCarburant: (json['quotaCarburant'] ?? 0).toDouble(),
      carburantId: json['carburantId']?.toString() ?? '',
      carburantNom: json['carburantNom'] ?? '',
      utilisateurId: json['utilisateurId']?.toString() ?? '',
      utilisateurNom: json['utilisateurNom'] ?? '',
      utilisateur: json['utilisateur'] != null
          ? User.fromJson(json['utilisateur'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "immatriculation": immatriculation,
      "marque": marque,
      "modele": modele,
      "quotaCarburant": quotaCarburant,
      "carburantId": carburantId,
      "carburantNom": carburantNom,
      "utilisateurId": utilisateurId,
      "utilisateurNom": utilisateurNom,
      if (utilisateur != null) "utilisateur": utilisateur!.toJson(),
    };
  }
}
