class Station {
  final String id;
  final String nom;
  final String adresse;
  final String ville;
  final bool actif;

  Station({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.ville,
    required this.actif,
  });

  factory Station.fromJson(Map<String, dynamic> json) {
    return Station(
      id: json['id'].toString(), // ✅ conversion int → String
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      actif: json['actif'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'adresse': adresse,
      'ville': ville,
      'actif': actif,
    };
  }
}
