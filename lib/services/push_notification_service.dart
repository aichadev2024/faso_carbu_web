import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import '../firebase_options.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PushNotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Récupère le token FCM Web ou mobile
  Future<String?> getTokenSafe() async {
    try {
      // Initialisation Firebase
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: kIsWeb ? DefaultFirebaseOptions.web : null,
        );
        if (kIsWeb) {
          print("Attente du Service Worker...");
          await Future.delayed(
            const Duration(milliseconds: 500),
          ); // 0.5s pour SW
        }
      }

      // Sur Web, demander la permission pour les notifications
      if (kIsWeb) {
        NotificationSettings settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (settings.authorizationStatus != AuthorizationStatus.authorized) {
          print("Permission refusée pour les notifications Web");
          return null;
        }

        // Petit délai pour s'assurer que le Service Worker est actif
        await Future.delayed(const Duration(milliseconds: 200));
      }

      // Récupérer le token
      String? token = await _messaging.getToken(
        vapidKey: kIsWeb
            ? "BBGcnHfw7ycA2JAJncMpF0ed-OxX3C77FNWExEfdntp3nYlYC-1Nu7-_qDK9H57m62lWjfuNR044l75Sdg31IE8"
            : null, // null sur mobile
      );

      if (token != null) {
        print("Token FCM : $token");
        return token;
      } else {
        print("Impossible de récupérer le token FCM");
        return null;
      }
    } catch (e) {
      print("Erreur lors de la récupération du token FCM : $e");
      return null;
    }
  }

  /// Envoie le token au backend avec le JWT
  Future<void> sendTokenToBackend({
    required String fcmToken,
    required String userId,
    required String jwtToken,
  }) async {
    try {
      const backendUrl =
          "https://faso-carbu-backend-2.onrender.com/api/utilisateurs/update-token";
      final response = await http.post(
        Uri.parse(backendUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $jwtToken",
        },
        body: jsonEncode({"userId": userId, "fcmToken": fcmToken}),
      );

      if (response.statusCode == 200) {
        print("Token envoyé au backend avec succès");
      } else {
        print(
          "Erreur lors de l'envoi du token : ${response.statusCode} ${response.body}",
        );
      }
    } catch (e) {
      print("Exception lors de l'envoi du token : $e");
    }
  }
}
