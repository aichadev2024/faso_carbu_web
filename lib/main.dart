import 'package:flutter/material.dart';
import 'package:gestionnaire_dashboard/screens/vehicule_form_screen.dart';
import 'package:provider/provider.dart';
import 'screens/user_form_screen.dart';
import 'screens/users_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_gestionnaire_screen.dart';
import 'package:gestionnaire_dashboard/screens/register_gestionnaire_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/station_list_screen.dart';
import 'screens/demande_list_screen.dart';
import 'providers/station_provider.dart';
import 'providers/demande_provider.dart';
import 'screens/demande_form_screen.dart';
import 'screens/vehicule_list_screen.dart';
import 'providers/vehicule_provider.dart';
import 'screens/tickets_screen.dart';
import 'providers/user_provider.dart';
import 'providers/carburant_provider.dart';
import 'screens/rapport_screen.dart';
import 'services/rapport_service.dart';
import 'screens/ProfilScreen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => StationProvider()),
        ChangeNotifierProvider(create: (_) => DemandeProvider()),
        ChangeNotifierProvider(create: (_) => VehiculeProvider()),
        ChangeNotifierProvider(create: (_) => CarburantProvider()),
      ],
      child: const GestionnaireDashboardApp(),
    ),
  );
}

class GestionnaireDashboardApp extends StatelessWidget {
  const GestionnaireDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestionnaire Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.blueAccent),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      onGenerateRoute: (settings) {
        final args = settings.arguments as Map<String, dynamic>?;

        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());

          case '/onboarding':
            return MaterialPageRoute(builder: (_) => const OnboardingScreen());

          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case '/register-gestionnaire':
            return MaterialPageRoute(
              builder: (_) => const RegisterGestionnaireScreen(),
            );

          case '/dashboard':
            return MaterialPageRoute(
              builder: (_) => const DashboardGestionnaireScreen(),
              settings: RouteSettings(arguments: args),
            );

          case '/users':
            return MaterialPageRoute(
              builder: (_) => UsersListScreen(),
              settings: RouteSettings(arguments: args),
            );

          case '/users/form':
            return MaterialPageRoute(
              builder: (_) => UserFormScreen(),
              settings: RouteSettings(arguments: args),
            );

          case '/stations':
            return MaterialPageRoute(
              builder: (_) =>
                  StationListScreen(jwtToken: args?['jwtToken'] ?? ''),
            );

          case '/demandes':
            return MaterialPageRoute(
              builder: (_) => DemandeListScreen(),
              settings: RouteSettings(arguments: args),
            );

          case '/demandes/form':
            return MaterialPageRoute(
              builder: (_) => DemandeFormScreen(),
              settings: RouteSettings(arguments: args),
            );

          case '/vehicules':
            return MaterialPageRoute(
              builder: (_) =>
                  VehiculeListScreen(jwtToken: args?['jwtToken'] ?? ''),
            );

          case '/vehicule/form':
            return MaterialPageRoute(
              builder: (_) =>
                  VehiculeFormScreen(jwtToken: args?['jwtToken'] ?? ''),
            );
          case '/rapports':
            return MaterialPageRoute(
              builder: (_) => RapportScreen(
                service: RapportService(
                  baseUrl: "https://faso-carbu-backend-2.onrender.com",
                  token: args?['jwtToken'] ?? '',
                ),
              ),
              settings: RouteSettings(arguments: args),
            );
          case '/profil':
            return MaterialPageRoute(
              builder: (_) => ProfilScreen(
                jwtToken: args?['jwtToken'] ?? '',
                userId: args?['userId'],
              ),
              settings: RouteSettings(arguments: args),
            );

          case '/tickets':
            return MaterialPageRoute(
              builder: (_) => const TicketsScreen(),
              settings: RouteSettings(arguments: args),
            );

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}
