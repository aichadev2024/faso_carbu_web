enum Role { CHAUFFEUR, DEMANDEUR, ADMIN_STATION, GESTIONNAIRE, AGENT_STATION }

class User {
  String? id;
  String name;
  Role role;

  User({this.id, required this.name, required this.role});

  // Convertir une String en Role
  static Role roleFromString(String roleString) => Role.values.firstWhere(
    (r) => r.name.toUpperCase() == roleString.toUpperCase(),
    orElse: () => Role.DEMANDEUR,
  );

  // Convertir un Role en String
  String roleToString() => role.name;

  // Créer un User depuis JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      role: roleFromString(json['role'] ?? 'DEMANDEUR'),
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() {
    final map = {'name': name, 'role': roleToString()};
    if (id != null) map['id'] = id!;
    return map;
  }
}
