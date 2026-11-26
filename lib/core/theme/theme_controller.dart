import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thème clair / sombre choisi par l'utilisateur, mémorisé dans le navigateur.
class ThemeController {
  ThemeController._();

  static const _key = 'theme_mode';
  static final mode = ValueNotifier<ThemeMode>(ThemeMode.light);

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mode.value = prefs.getString(_key) == 'dark' ? ThemeMode.dark : ThemeMode.light;
    } catch (_) {
      // Stockage indisponible (navigation privée...) : thème clair.
    }
  }

  static Future<void> toggle() async {
    mode.value = mode.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.value == ThemeMode.dark ? 'dark' : 'light');
    } catch (_) {}
  }
}
