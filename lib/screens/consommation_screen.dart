import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import 'consommation_form_screen.dart';
import 'main_layout.dart';

class ConsommationScreen extends StatefulWidget {
  const ConsommationScreen({super.key});

  @override
  State<ConsommationScreen> createState() => _ConsommationScreenState();
}

class _ConsommationScreenState extends State<ConsommationScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await http.get(
        Uri.parse('${AppConfig.apiUrl}/consommations'),
        headers: {'Authorization': 'Bearer ${Session.token}'},
      );
      if (res.statusCode != 200) throw Exception(res.statusCode);
      final data = (jsonDecode(utf8.decode(res.bodyBytes)) as List).cast<Map<String, dynamic>>();
      data.sort((a, b) => (b['dateConsommation'] ?? '').toString().compareTo((a['dateConsommation'] ?? '').toString()));
      if (mounted) setState(() => _items = data);
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les consommations.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/consommations/form'),
        builder: (_) => const ConsommationFormScreen(),
      ),
    );
    if (saved == true && mounted) _load();
  }

  static double _qty(Map<String, dynamic> c) => double.tryParse('${c['quantiteUtilisee'] ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final total = _items.fold<double>(0, (s, c) => s + _qty(c));
    final now = DateTime.now();
    final thisMonth = _items.where((c) {
      final d = DateTime.tryParse('${c['dateConsommation'] ?? ''}');
      return d != null && d.year == now.year && d.month == now.month;
    }).fold<double>(0, (s, c) => s + _qty(c));

    return MainLayout(
      title: 'Consommations',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Pilotage',
            icon: Icons.local_drink_rounded,
            title: 'Consommations',
            subtitle: 'Carburant effectivement utilisé sur les attributions.',
            actions: [
              FilledButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Saisir une consommation'),
              ),
            ],
          ),
          if (!_loading && _error == null) ...[
            ResponsiveGrid(maxColumns: 3, children: [
              StatCard(label: 'Ce mois-ci', value: '${formatNumber(thisMonth)} L', icon: Icons.calendar_month_rounded),
              StatCard(label: 'Total consommé', value: '${formatNumber(total)} L', icon: Icons.water_drop_rounded, tone: Tone.info),
              StatCard(label: 'Saisies', value: '${_items.length}', icon: Icons.receipt_long_rounded, tone: Tone.neutral),
            ]),
            const SizedBox(height: AppSpacing.xl),
          ],
          Card(
            clipBehavior: Clip.antiAlias,
            child: _loading
                ? const LoadingView()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : _items.isEmpty
                        ? EmptyState(
                            icon: Icons.local_drink_outlined,
                            title: 'Aucune consommation',
                            message: 'Saisissez le carburant utilisé pour suivre l\'usage réel de chaque attribution.',
                            action: FilledButton(onPressed: _openForm, child: const Text('Saisir une consommation')),
                          )
                        : AppDataTable(
                            columns: const [
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('CARBURANT')),
                              DataColumn(label: Text('QUANTITÉ'), numeric: true),
                              DataColumn(label: Text('COMMENTAIRE')),
                            ],
                            rows: [
                              for (final c in _items)
                                DataRow(cells: [
                                  DataCell(Text(formatDate(DateTime.tryParse('${c['dateConsommation'] ?? ''}'), withTime: true))),
                                  DataCell(Text((c['carburant'] is Map ? c['carburant']['nom'] : null)?.toString() ?? '—')),
                                  DataCell(Text('${formatNumber(_qty(c), decimals: 1)} L')),
                                  DataCell(ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 360),
                                    child: Text(
                                      (c['commentaire'] ?? '').toString().isEmpty ? '—' : c['commentaire'].toString(),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                                ]),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
