class StationAvecAdminRequest {
  String nomStation;
  String adresseStation;
  String villeStation;
  String nomAdmin;
  String prenomAdmin;
  String emailAdmin;
  String telephoneAdmin;
  String motDePasseAdmin;

  StationAvecAdminRequest({
    required this.nomStation,
    required this.adresseStation,
    required this.villeStation,
    required this.nomAdmin,
    required this.prenomAdmin,
    required this.emailAdmin,
    required this.telephoneAdmin,
    required this.motDePasseAdmin,
  });

  Map<String, dynamic> toJson() {
    return {
      'nomStation': nomStation,
      'adresseStation': adresseStation,
      'villeStation': villeStation,
      'nomAdmin': nomAdmin,
      'prenomAdmin': prenomAdmin,
      'emailAdmin': emailAdmin,
      'telephoneAdmin': telephoneAdmin,
      'motDePasseAdmin': motDePasseAdmin,
    };
  }
}
