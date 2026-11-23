import 'core/config/app_config.dart';

@Deprecated('Utiliser AppConfig')
class Config {
  static const String apiUrl = AppConfig.apiUrl;
  static String? token;
}
