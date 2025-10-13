import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/DashboardService.dart';
import '../services/push_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class DashboardGestionnaireScreen extends StatefulWidget {
  const DashboardGestionnaireScreen({super.key});

  @override
  State<DashboardGestionnaireScreen> createState() =>
      _DashboardGestionnaireScreenState();
}

class _DashboardGestionnaireScreenState
    extends State<DashboardGestionnaireScreen> {
  int _selectedIndex = 0;
  String userFullName = '';
  String userRole = '';
  int userCount = 0;
  int stationCount = 0;
  int vehiculeCount = 0;

  final List<_NavItem> _navItems = const [
    _NavItem('Tableau de bord', Icons.dashboard_outlined, '/dashboard'),
    _NavItem('Utilisateurs', Icons.people_alt_outlined, '/users'),
    _NavItem('Stations', Icons.local_gas_station_outlined, '/stations'),
    _NavItem('Véhicules', Icons.directions_car_filled_outlined, '/vehicules'),
    _NavItem('Tickets carburant', Icons.qr_code_2_outlined, '/tickets'),
    _NavItem(
      'Attributions',
      Icons.assignment_turned_in_outlined,
      '/attributions',
    ),
    _NavItem('Rapports', Icons.bar_chart_outlined, '/rapports'),
    _NavItem('Demandes', Icons.pending_actions_outlined, '/demandes'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
      _setupPushNotifications();
      _listenToNotifications();
    });
  }

  // ================== 🔔 Notifications Push ==================
  Future<void> _setupPushNotifications() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final jwtToken = args?['jwtToken'] ?? '';

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? '';

    final pushService = PushNotificationService();
    final fcmToken = await pushService.getTokenSafe();

    if (fcmToken != null && userId.isNotEmpty) {
      await pushService.sendTokenToBackend(
        fcmToken: fcmToken,
        userId: userId,
        jwtToken: jwtToken,
      );
    }
  }

  void _listenToNotifications() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        final title = message.notification!.title ?? '';
        final body = message.notification!.body ?? '';

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$title : $body"),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF003B46),
          ),
        );
      }
    });
  }

  // ================== 📊 Charger les données du tableau de bord ==================
  Future<void> _loadDashboardData() async {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final jwtToken = args?['jwtToken'] ?? '';

    final prefs = await SharedPreferences.getInstance();

    // ✅ Correction des accents
    String decodeUtf8(String value) {
      try {
        return utf8.decode(value.runes.toList());
      } catch (_) {
        return value;
      }
    }

    final firstName = decodeUtf8(prefs.getString('prenom') ?? '');
    final lastName = decodeUtf8(prefs.getString('nom') ?? '');
    final role = decodeUtf8(prefs.getString('role') ?? '');

    if (!mounted) return;
    setState(() {
      userFullName = '$firstName $lastName';
      userRole = role.isNotEmpty ? role : 'Gestionnaire';
    });

    final service = DashboardService(
      baseUrl: 'https://faso-carbu-backend-2.onrender.com',
    );

    try {
      final users = await service.getUserCount(jwtToken);
      final stations = await service.getStationCount(jwtToken);
      final vehicules = await service.getVehiculeCount(jwtToken);

      if (!mounted) return;
      setState(() {
        userCount = users;
        stationCount = stations;
        vehiculeCount = vehicules;
      });
    } catch (e) {
      debugPrint('❌ Erreur récupération dashboard: $e');
    }
  }

  // ================== 🧭 Navigation ==================
  void _selectNav(int index, String jwtToken) {
    setState(() => _selectedIndex = index);
    Navigator.pushNamed(
      context,
      _navItems[index].route,
      arguments: {'jwtToken': jwtToken},
    );
  }

  // ================== 🖼️ Interface ==================
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final jwtToken = args?['jwtToken'] ?? '';
    final isWide = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          /// 🌊 Barre latérale
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isWide ? 240 : 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF003B46),
                  Color(0xFF07575B),
                  Color(0xFF0E9AA7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: CustomSidebar(
              items: _navItems,
              selectedIndex: _selectedIndex,
              onTap: (i) => _selectNav(i, jwtToken),
            ),
          ),

          /// 🧭 Contenu principal
          Expanded(
            child: Column(
              children: [
                /// 🏷️ Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0E9AA7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.dashboard, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "Tableau de bord",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                userFullName.isNotEmpty
                                    ? userFullName
                                    : "Chargement...",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                userRole.isNotEmpty ? userRole : "Gestionnaire",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<String>(
                            color: const Color(0xFF07575B),
                            onSelected: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (value == 'profil') {
                                final userId = prefs.getString('userId');
                                if (!mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  '/profil',
                                  arguments: {
                                    'jwtToken': jwtToken,
                                    'userId': userId,
                                  },
                                );
                              } else if (value == 'logout') {
                                await prefs.remove('jwtToken');
                                if (!mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                value: 'profil',
                                child: Text(
                                  'Profil',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Text(
                                  'Déconnexion',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                            child: Row(
                              children: const [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0xFF003B46),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 🧮 Corps principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: isWide ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.5,
                          children: [
                            DashboardCardModern(
                              color: const Color(0xFF003B46),
                              icon: Icons.people,
                              title: "Utilisateurs",
                              number: "$userCount",
                            ),
                            DashboardCardModern(
                              color: const Color(0xFF07575B),
                              icon: Icons.local_gas_station,
                              title: "Stations",
                              number: "$stationCount",
                            ),
                            DashboardCardModern(
                              color: const Color(0xFF0E9AA7),
                              icon: Icons.directions_car,
                              title: "Véhicules",
                              number: "$vehiculeCount",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/tickets',
                              arguments: {'jwtToken': jwtToken},
                            );
                          },
                          icon: const Icon(Icons.qr_code),
                          label: const Text("Voir mes tickets"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003B46),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Expanded(flex: 2, child: _RapportsSection()),
                            SizedBox(width: 20),
                            Expanded(flex: 1, child: _NotificationsSection()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================== 📦 Widgets annexes ==================
class CustomSidebar extends StatelessWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const CustomSidebar({
    required this.items,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          "FasoCarbu",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 30),
        Expanded(
          child: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final selected = i == selectedIndex;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        color: selected
                            ? const Color(0xFF0E9AA7)
                            : Colors.white70,
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          item.title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? const Color(0xFF0E9AA7)
                                : Colors.white70,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class DashboardCardModern extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final String number;

  const DashboardCardModern({
    required this.color,
    required this.icon,
    required this.title,
    required this.number,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  number,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RapportsSection extends StatelessWidget {
  const _RapportsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: const Center(
        child: Text(
          "📈 Rapport mensuel en préparation...",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

class _NotificationsSection extends StatelessWidget {
  const _NotificationsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Notifications",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF003B46),
            ),
          ),
          SizedBox(height: 16),
          NotificationTile(
            icon: Icons.check_circle,
            title: "Ticket validé",
            subtitle: "Un ticket a été validé avec succès",
            color: Colors.green,
          ),
          NotificationTile(
            icon: Icons.warning_amber_rounded,
            title: "Attention",
            subtitle: "Une station a signalé un problème",
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003B46),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String title;
  final IconData icon;
  final String route;
  const _NavItem(this.title, this.icon, this.route);
}
