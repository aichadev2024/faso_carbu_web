class Demande {
  final int id;
  final double quantite;
  final String statut;
  final String carburantNom;
  final String stationNom;
  final String vehiculeImmatriculation;

  // 🔹 Noms/prénoms du demandeur et gestionnaire
  final String? demandeurNom;
  final String? demandeurPrenom;
  final String? gestionnaireNom;
  final String? gestionnairePrenom;

  // 🔹 Nouvel attribut entrepriseId
  final String? entrepriseId;

  Demande({
    required this.id,
    required this.quantite,
    required this.statut,
    required this.carburantNom,
    required this.stationNom,
    required this.vehiculeImmatriculation,
    this.demandeurNom,
    this.demandeurPrenom,
    this.gestionnaireNom,
    this.gestionnairePrenom,
    this.entrepriseId,
  });

  factory Demande.fromJson(Map<String, dynamic> json) {
    return Demande(
      id: int.tryParse(json['id'].toString()) ?? 0, // ✅ Cast String → int
      quantite: (json['quantite'] ?? 0).toDouble(),
      statut: json['statut'] ?? 'EN_ATTENTE',
      carburantNom: json['carburantNom'] ?? '',
      stationNom: json['stationNom'] ?? '',
      vehiculeImmatriculation: json['vehiculeImmatriculation'] ?? '',
      demandeurNom: json['demandeurNom'],
      demandeurPrenom: json['demandeurPrenom'],
      gestionnaireNom: json['gestionnaireNom'],
      gestionnairePrenom: json['gestionnairePrenom'],
      entrepriseId: json['entrepriseId']?.toString(), // ✅ converti en String
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quantite': quantite,
      'statut': statut,
      'carburantNom': carburantNom,
      'stationNom': stationNom,
      'vehiculeImmatriculation': vehiculeImmatriculation,
      'demandeurNom': demandeurNom,
      'demandeurPrenom': demandeurPrenom,
      'gestionnaireNom': gestionnaireNom,
      'gestionnairePrenom': gestionnairePrenom,
      'entrepriseId': entrepriseId, // ✅ ajouté
    };
  }

  Demande copyWith({
    int? id,
    double? quantite,
    String? statut,
    String? carburantNom,
    String? stationNom,
    String? vehiculeImmatriculation,
    String? demandeurNom,
    String? demandeurPrenom,
    String? gestionnaireNom,
    String? gestionnairePrenom,
    String? entrepriseId,
  }) {
    return Demande(
      id: id ?? this.id,
      quantite: quantite ?? this.quantite,
      statut: statut ?? this.statut,
      carburantNom: carburantNom ?? this.carburantNom,
      stationNom: stationNom ?? this.stationNom,
      vehiculeImmatriculation:
          vehiculeImmatriculation ?? this.vehiculeImmatriculation,
      demandeurNom: demandeurNom ?? this.demandeurNom,
      demandeurPrenom: demandeurPrenom ?? this.demandeurPrenom,
      gestionnaireNom: gestionnaireNom ?? this.gestionnaireNom,
      gestionnairePrenom: gestionnairePrenom ?? this.gestionnairePrenom,
      entrepriseId: entrepriseId ?? this.entrepriseId,
    );
  }
}
