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
      // Le backend expose `id_station` (entité) ou `id` (DTO) selon l'endpoint.
      id: (json['id'] ?? json['id_station'] ?? json['idStation']).toString(),
      nom: json['nom'] ?? '',
      adresse: json['adresse'] ?? '',
      ville: json['ville'] ?? '',
      actif: json['actif'] ?? ((json['statut'] ?? 'actif').toString().toLowerCase() == 'actif'),
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
