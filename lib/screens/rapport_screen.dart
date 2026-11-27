// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/role.dart' show Role;
import '../models/user.dart';
import '../providers/user_provider.dart';
import '../services/rapport_service.dart';
import 'main_layout.dart';

class RapportScreen extends StatefulWidget {
  const RapportScreen({super.key, required this.service});
  final RapportService service;

  @override
  State<RapportScreen> createState() => _RapportScreenState();
}

class _RapportScreenState extends State<RapportScreen> {
  List<User> _chauffeurs = [];
  String? _chauffeurId;
  DateTimeRange? _periode;
  List<dynamic> _tickets = [];
  bool _loadingChauffeurs = true;
  bool _loading = false;
  bool _searched = false;
  String? _exporting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChauffeurs());
  }

  Future<void> _loadChauffeurs() async {
    final provider = context.read<UserProvider>();
    try {
      await provider.loadUsers();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _chauffeurs = provider.users.where((u) => u.role == Role.CHAUFFEUR).toList();
      _loadingChauffeurs = false;
    });
  }

  Future<void> _search() async {
    if (_chauffeurId == null) return;
    setState(() {
      _loading = true;
      _searched = true;
    });
    try {
      final p = _periode;
      final result = p == null
          ? await widget.service.getTicketsParChauffeur(_chauffeurId!)
          : await widget.service.getTicketsParChauffeurEtDates(
              _chauffeurId!,
              p.start,
              DateTime(p.end.year, p.end.month, p.end.day, 23, 59, 59),
            );
      if (mounted) setState(() => _tickets = result);
    } catch (_) {
      if (mounted) showAppSnack(context, 'Impossible de générer le rapport.', tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickPeriode() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _periode ?? DateTimeRange(start: DateTime(now.year, now.month), end: now),
      helpText: 'Période du rapport',
      saveText: 'Appliquer',
    );
    if (picked != null) setState(() => _periode = picked);
  }

  void _download(List<int> bytes, String filename, String mime) {
    final blob = html.Blob([bytes], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..download = filename
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _export(String format) async {
    setState(() => _exporting = format);
    try {
      if (format == 'pdf') {
        final r = await widget.service.exporterRapportPDF();
        _download(r.bodyBytes, 'rapport-consommation.pdf', 'application/pdf');
      } else {
        final r = await widget.service.exporterRapportExcel();
        _download(r.bodyBytes, 'rapport-consommation.xlsx',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      }
      if (mounted) showAppSnack(context, 'Rapport téléchargé.', tone: Tone.success);
    } catch (_) {
      if (mounted) showAppSnack(context, 'L\'export a échoué.', tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  static double _n(dynamic v) => double.tryParse('${v ?? 0}') ?? 0;

  @override
  Widget build(BuildContext context) {
    final litres = _tickets.fold<double>(0, (s, t) => s + _n(t['quantite']));
    final montant = _tickets.fold<double>(0, (s, t) => s + _n(t['montant']));

    return MainLayout(
      title: 'Rapports',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            eyebrow: 'Pilotage',
            icon: Icons.insert_chart_rounded,
            title: 'Rapports',
            subtitle: 'Analysez les tickets par chauffeur et exportez les consommations.',
            actions: [
              OutlinedButton.icon(
                onPressed: _exporting != null ? null : () => _export('excel'),
                icon: _exporting == 'excel'
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.table_chart_outlined, size: 18),
                label: const Text('Export Excel'),
              ),
              OutlinedButton.icon(
                onPressed: _exporting != null ? null : () => _export('pdf'),
                icon: _exporting == 'pdf'
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.picture_as_pdf_outlined, size: 18),
                label: const Text('Export PDF'),
              ),
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: 280,
                    child: AppDropdown<String>(
                      label: 'Chauffeur',
                      icon: Icons.badge_outlined,
                      hint: _loadingChauffeurs
                          ? 'Chargement…'
                          : (_chauffeurs.isEmpty ? 'Aucun chauffeur' : 'Choisir un chauffeur'),
                      value: _chauffeurId,
                      items: [
                        for (final c in _chauffeurs)
                          DropdownMenuItem(value: c.id, child: Text('${c.prenom} ${c.nom}')),
                      ],
                      onChanged: (v) => setState(() => _chauffeurId = v),
                    ),
                  ),
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const FieldLabel('Période'),
                        OutlinedButton.icon(
                          onPressed: _pickPeriode,
                          icon: const Icon(Icons.date_range_outlined, size: 18),
                          label: Text(
                            _periode == null
                                ? 'Toutes les dates'
                                : '${formatDate(_periode!.start)} → ${formatDate(_periode!.end)}',
                          ),
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        ),
                      ],
                    ),
                  ),
                  if (_periode != null)
                    TextButton(onPressed: () => setState(() => _periode = null), child: const Text('Effacer la période')),
                  PrimaryButton(
                    label: 'Générer',
                    icon: Icons.insights_rounded,
                    loading: _loading,
                    onPressed: _chauffeurId == null ? null : _search,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!_searched)
            const Card(
              child: EmptyState(
                icon: Icons.insert_chart_outlined_rounded,
                title: 'Choisissez un chauffeur',
                message: 'Sélectionnez un chauffeur et, si besoin, une période, puis cliquez sur « Générer ».',
              ),
            )
          else if (_loading)
            const LoadingView()
          else ...[
            ResponsiveGrid(maxColumns: 3, children: [
              StatCard(label: 'Tickets', value: '${_tickets.length}', icon: Icons.confirmation_number_rounded),
              StatCard(label: 'Volume', value: '${formatNumber(litres)} L', icon: Icons.water_drop_rounded, tone: Tone.info),
              StatCard(label: 'Montant', value: formatNumber(montant), hint: 'FCFA', icon: Icons.payments_rounded, tone: Tone.success),
            ]),
            const SizedBox(height: AppSpacing.lg),
            Card(
              clipBehavior: Clip.antiAlias,
              child: _tickets.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun ticket',
                      message: 'Aucun ticket pour ce chauffeur sur la période choisie.',
                    )
                  : AppDataTable(
                      columns: const [
                        DataColumn(label: Text('N°')),
                        DataColumn(label: Text('ÉMIS LE')),
                        DataColumn(label: Text('STATION')),
                        DataColumn(label: Text('QUANTITÉ'), numeric: true),
                        DataColumn(label: Text('MONTANT'), numeric: true),
                        DataColumn(label: Text('STATUT')),
                      ],
                      rows: [
                        for (final t in _tickets)
                          DataRow(cells: [
                            DataCell(Text('#${t['id']}')),
                            DataCell(Text(formatDate(DateTime.tryParse('${t['dateEmission'] ?? ''}'), withTime: true))),
                            DataCell(Text('${t['stationNom'] ?? '—'}')),
                            DataCell(Text('${formatNumber(_n(t['quantite']))} L')),
                            DataCell(Text('${formatNumber(_n(t['montant']))} FCFA')),
                            DataCell(StatusBadge.fromStatus(t['statut']?.toString())),
                          ]),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
