import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ------------------------------------------------------------
/// DASHBOARD GESTIONNAIRE — Design Coloré & Moderne (2025)
/// ------------------------------------------------------------
class DashboardGestionnaireScreen extends StatefulWidget {
  const DashboardGestionnaireScreen({super.key});

  @override
  State<DashboardGestionnaireScreen> createState() =>
      _DashboardGestionnaireScreenState();
}

class _DashboardGestionnaireScreenState
    extends State<DashboardGestionnaireScreen> {
  int _selectedIndex = 0;

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

  void _navigateTo(String route, String jwtToken) {
    Navigator.pushNamed(context, route, arguments: {'jwtToken': jwtToken});
  }

  void _selectNav(int index, String jwtToken) {
    setState(() => _selectedIndex = index);
    _navigateTo(_navItems[index].route, jwtToken);
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
    final jwtToken = args?['jwtToken'] ?? '';

    final isWide = MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          /// 🟦 Sidebar modernisée
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isWide ? 240 : 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF233E94)],
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

          /// 🧡 Contenu principal
          Expanded(
            child: Column(
              children: [
                /// Header stylisé
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.dashboard, color: Color(0xFF1E3A8A)),
                      const SizedBox(width: 10),
                      const Text(
                        "Tableau de bord",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: const [
                              Text(
                                "Diarrassouba Aïcha",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                "Gestionnaire",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 10),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              if (value == 'profil') {
                                final userId = prefs.getString('userId');
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
                                child: Text('Profil'),
                              ),
                              PopupMenuItem(
                                value: 'logout',
                                child: Text('Déconnexion'),
                              ),
                            ],
                            child: Row(
                              children: const [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0xFF1E3A8A),
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.black87,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                /// 🟩 Corps du dashboard
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Cartes colorées
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: isWide ? 3 : 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 2.5,
                          children: const [
                            DashboardCardModern(
                              color: Color(0xFF1E3A8A),
                              icon: Icons.people,
                              title: "Utilisateurs",
                              number: "128",
                            ),
                            DashboardCardModern(
                              color: Color(0xFFFFB300),
                              icon: Icons.local_gas_station,
                              title: "Stations",
                              number: "42",
                            ),
                            DashboardCardModern(
                              color: Color(0xFF43A047),
                              icon: Icons.directions_car,
                              title: "Véhicules",
                              number: "85",
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        /// Bouton tickets
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
                            backgroundColor: const Color(0xFFFF9800),
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

                        /// Graphique + notifications
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Graphique
                            Expanded(
                              flex: 2,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Rapports mensuels",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    SizedBox(
                                      height: 240,
                                      child: BarChart(
                                        BarChartData(
                                          gridData: FlGridData(show: false),
                                          borderData: FlBorderData(show: false),
                                          titlesData: FlTitlesData(
                                            leftTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: false,
                                              ),
                                            ),
                                            bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                showTitles: true,
                                                getTitlesWidget: (value, _) {
                                                  const months = [
                                                    "Jan",
                                                    "Fév",
                                                    "Mar",
                                                    "Avr",
                                                    "Mai",
                                                  ];
                                                  if (value.toInt() <
                                                      months.length) {
                                                    return Text(
                                                      months[value.toInt()],
                                                    );
                                                  }
                                                  return const Text("");
                                                },
                                              ),
                                            ),
                                          ),
                                          barGroups: List.generate(5, (i) {
                                            return BarChartGroupData(
                                              x: i,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: 20 + i * 5,
                                                  gradient:
                                                      const LinearGradient(
                                                        colors: [
                                                          Color(0xFFFFB74D),
                                                          Color(0xFFFF9800),
                                                        ],
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                      ),
                                                  width: 18,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                              ],
                                            );
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),

                            /// Notifications
                            Expanded(
                              flex: 1,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 10,
                                      offset: Offset(0, 4),
                                    ),
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
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    NotificationTile(
                                      icon: Icons.check_circle,
                                      title: "Ticket validé",
                                      subtitle:
                                          "Un ticket a été validé avec succès",
                                      color: Colors.green,
                                    ),
                                    NotificationTile(
                                      icon: Icons.warning_amber_rounded,
                                      title: "Attention",
                                      subtitle:
                                          "Une station a signalé un problème",
                                      color: Colors.orange,
                                    ),
                                    NotificationTile(
                                      icon: Icons.info_outline,
                                      title: "Info système",
                                      subtitle:
                                          "Nouvelle mise à jour disponible",
                                      color: Colors.indigo,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

/// ===================================================
/// UI Components Modernes
/// ===================================================
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
                        color: Colors.white.withOpacity(selected ? 1 : 0.8),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(selected ? 1 : 0.8),
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
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

/// ===================================================
/// Widgets Modernes (Cards & Notifications)
/// ===================================================
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
        color: color.withOpacity(0.1),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
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
                    color: Colors.black87,
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

/// ===================================================
/// Navigation Item
/// ===================================================
class _NavItem {
  final String title;
  final IconData icon;
  final String route;

  const _NavItem(this.title, this.icon, this.route);
}
