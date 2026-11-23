/// Configuration de l'application, injectée à la compilation :
///   flutter run -d chrome --dart-define=API_URL=http://localhost:9090
///   flutter build web --dart-define=API_URL=https://api.fasocarbu.bf
class AppConfig {
  AppConfig._();

  /// Racine du backend, sans `/api` ni slash final.
  static const String backendUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:9090',
  );

  /// Racine des endpoints REST (`<backend>/api`).
  static const String apiUrl = '$backendUrl/api';
}
