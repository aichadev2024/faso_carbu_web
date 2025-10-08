class Ticket {
  final int? id;
  final DateTime? dateEmission;
  final DateTime? dateValidation;
  final double? montant;
  final double? quantite;
  final String? statut;
  final String? codeQr;

  // Champs DTO
  final String? utilisateurNom;
  final String? utilisateurPrenom;
  final String? validateurNom;
  final String? validateurPrenom;
  final String? stationNom;
  final String? vehiculeImmatriculation;
  final String? carburantNom;

  // ✅ nouveaux champs
  final int? entrepriseId;
  final String? entrepriseNom;

  // ✅ somme calculée (backend)
  final double? somme;

  Ticket({
    this.id,
    this.dateEmission,
    this.dateValidation,
    this.montant,
    this.quantite,
    this.statut,
    this.codeQr,
    this.utilisateurNom,
    this.utilisateurPrenom,
    this.validateurNom,
    this.validateurPrenom,
    this.stationNom,
    this.vehiculeImmatriculation,
    this.carburantNom,
    this.entrepriseId,
    this.entrepriseNom,
    this.somme, // 🔹 ajouté
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDate(dynamic v) =>
        (v == null) ? null : DateTime.tryParse(v.toString());

    double? _num(dynamic v) =>
        (v == null) ? null : double.tryParse(v.toString());

    return Ticket(
      id: json['id'],
      dateEmission: _parseDate(json['dateEmission']),
      dateValidation: _parseDate(json['dateValidation']),
      montant: _num(json['montant']),
      quantite: _num(json['quantite']),
      statut: json['statut'],
      codeQr: json['codeQr'],
      utilisateurNom: json['utilisateurNom'],
      utilisateurPrenom: json['utilisateurPrenom'],
      validateurNom: json['validateurNom'],
      validateurPrenom: json['validateurPrenom'],
      stationNom: json['stationNom'],
      vehiculeImmatriculation: json['vehiculeImmatriculation'],
      carburantNom: json['carburantNom'],
      entrepriseId: json['entrepriseId'],
      entrepriseNom: json['entrepriseNom'],
      somme: _num(json['somme']), // 🔹 récupéré depuis backend
    );
  }

  static String formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
