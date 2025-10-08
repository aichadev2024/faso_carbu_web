class VehiculeRequest {
  final String immatriculation;
  final String marque;
  final String modele;
  final double quotaCarburant;
  final String carburantId; // ID du carburant sélectionné
  final String userId; // ID de l'utilisateur associé au véhicule

  VehiculeRequest({
    required this.immatriculation,
    required this.marque,
    required this.modele,
    required this.quotaCarburant,
    required this.carburantId,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    return {
      "immatriculation": immatriculation,
      "marque": marque,
      "modele": modele,
      "quotaCarburant": quotaCarburant,
      "carburantId": carburantId,
      "userId": userId,
    };
  }
}
