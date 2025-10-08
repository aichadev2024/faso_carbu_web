class Entreprise {
  final String id;
  final String nom;
  final String? adresse;

  Entreprise({required this.id, required this.nom, this.adresse});

  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      id: json['id']?.toString() ?? '',
      nom: json['nom'] ?? '',
      adresse: json['adresse'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'adresse': adresse};
  }
}
