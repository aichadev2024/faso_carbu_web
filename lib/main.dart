import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/session.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'firebase_options.dart';
import 'providers/carburant_provider.dart';
import 'providers/demande_provider.dart';
import 'providers/station_provider.dart';
import 'providers/user_provider.dart';
import 'providers/vehicule_provider.dart';
import 'screens/ProfilScreen.dart';
import 'screens/change_password_screen.dart';
import 'screens/consommation_screen.dart';
import 'screens/dashboard_gestionnaire_screen.dart';
import 'screens/demande_form_screen.dart';
import 'screens/demande_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/rapport_screen.dart';
import 'screens/register_gestionnaire_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/station_list_screen.dart';
import 'screens/tickets_screen.dart';
import 'screens/user_form_screen.dart';
import 'screens/users_list_screen.dart';
import 'screens/vehicule_form_screen.dart';
import 'screens/vehicule_list_screen.dart';
import 'services/rapport_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  } catch (e) {
    debugPrint('Firebase indisponible : $e');
  }
  await Session.load();
  await ThemeController.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => DemandeProvider()),
        ChangeNotifierProvider(create: (_) => VehiculeProvider()),
        ChangeNotifierProvider(create: (_) => CarburantProvider()),
      ],
      child: const FasoCarbuApp(),
    ),
  );
}

/// Routes accessibles sans être connecté.
const _publicRoutes = {'/', '/login', '/register-gestionnaire'};

class FasoCarbuApp extends StatelessWidget {
  const FasoCarbuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) => MaterialApp(
        title: 'FasoCarbu · Gestionnaire',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: mode,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // L'URL du navigateur (#/demandes...) ouvre directement la bonne page,
        // y compris après un rafraîchissement.
        onGenerateInitialRoutes: (name) => [_onGenerateRoute(RouteSettings(name: name))],
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  static Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    var name = settings.name ?? '/';

    // Pages protégées : retour à la connexion si pas de session.
    if (!_publicRoutes.contains(name) && !Session.isLoggedIn) {
      name = '/login';
    }

    // Le token vient des arguments si fournis, sinon de la session
    // (indispensable après un rafraîchissement de la page web).
    final passed = settings.arguments is Map<String, dynamic> ? settings.arguments as Map<String, dynamic> : const <String, dynamic>{};
    final args = {...Session.routeArgs, ...passed};
    final token = (args['jwtToken'] as String?)?.isNotEmpty == true ? args['jwtToken'] as String : Session.token;
    final routeSettings = RouteSettings(name: name, arguments: args);

    Widget page;
    switch (name) {
      case '/':
        page = const SplashScreen();
      case '/login':
        page = const LoginScreen();
      case '/register-gestionnaire':
        page = const RegisterGestionnaireScreen();
      case '/dashboard':
        page = const DashboardGestionnaireScreen();
      case '/users':
        page = UsersListScreen();
      case '/users/form':
        page = const UserFormScreen();
      case '/stations':
        page = StationListScreen(jwtToken: token);
      case '/demandes':
        page = DemandeListScreen();
      case '/demandes/form':
        page = const DemandeFormScreen();
      case '/vehicules':
        page = VehiculeListScreen(jwtToken: token);
      case '/vehicule/form':
        page = VehiculeFormScreen(jwtToken: token);
      case '/tickets':
        page = const TicketsScreen();
      case '/consommations':
        page = ConsommationScreen();
      case '/rapports':
        page = RapportScreen(
          service: RapportService(baseUrl: AppConfig.backendUrl, token: token),
        );
      case '/profil':
        page = ProfilScreen(jwtToken: token, userId: (args['userId'] as String?) ?? Session.userId);
      case '/change-password':
        page = ChangePasswordScreen(token: token);
      default:
        page = Session.isLoggedIn ? const DashboardGestionnaireScreen() : const LoginScreen();
    }

    // Transitions sobres : simple fondu entre les pages.
    return PageRouteBuilder(
      settings: routeSettings,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 160),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(opacity: animation, child: child),
    );
  }
}
