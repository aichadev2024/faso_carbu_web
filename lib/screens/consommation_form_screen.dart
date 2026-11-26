import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import 'main_layout.dart';

class ConsommationFormScreen extends StatefulWidget {
  const ConsommationFormScreen({super.key});

  @override
  State<ConsommationFormScreen> createState() => _ConsommationFormScreenState();
}

class _ConsommationFormScreenState extends State<ConsommationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantite = TextEditingController();
  final _commentaire = TextEditingController();
  List<Map<String, dynamic>> _attributions = [];
  List<Map<String, dynamic>> _carburants = [];
  String? _attribution;
  String? _carburant;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer ${Session.token}',
        'Content-Type': 'application/json',
      };

  @override
  void initState() {
    super.initState();
    _loadLists();
  }

  @override
  void dispose() {
    _quantite.dispose();
    _commentaire.dispose();
    super.dispose();
  }

  Future<void> _loadLists() async {
    try {
      final res = await Future.wait([
        http.get(Uri.parse('${AppConfig.apiUrl}/attributions'), headers: _headers),
        http.get(Uri.parse('${AppConfig.apiUrl}/carburants'), headers: _headers),
      ]);
      List<Map<String, dynamic>> parse(http.Response r) =>
          r.statusCode == 200 ? (jsonDecode(utf8.decode(r.bodyBytes)) as List).cast<Map<String, dynamic>>() : [];
      _attributions = parse(res[0]);
      _carburants = parse(res[1]);
    } catch (_) {
      _error = 'Les listes n\'ont pas pu être chargées.';
    }
    if (mounted) setState(() => _loading = false);
  }

  String _attributionLabel(Map<String, dynamic> a) {
    final date = formatDate(DateTime.tryParse('${a['dateAttribution'] ?? ''}'));
    final qte = formatNumber(double.tryParse('${a['quantite'] ?? 0}'));
    final ch = a['chauffeur'];
    final nom = ch is Map ? '${ch['prenom'] ?? ''} ${ch['nom'] ?? ''}'.trim() : '';
    return [if (nom.isNotEmpty) nom, '$qte L', date].join(' · ');
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final res = await http.post(
        Uri.parse('${AppConfig.apiUrl}/consommations'),
        headers: _headers,
        body: jsonEncode({
          'attributionId': _attribution,
          'carburantId': _carburant,
          'quantiteUtilisee': double.parse(_quantite.text.replaceAll(',', '.')),
          'commentaire': _commentaire.text.trim(),
        }),
      );
      if (res.statusCode != 200 && res.statusCode != 201) throw Exception(res.body);
      if (!mounted) return;
      showAppSnack(context, 'Consommation enregistrée.', tone: Tone.success);
      Navigator.pop(context, true);
    } catch (_) {
      setState(() => _error = 'Enregistrement impossible. Vérifiez les informations saisies.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Saisir une consommation',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const BackLink(label: 'Consommations'),
          const PageHeader(
            eyebrow: 'Consommations',
            icon: Icons.local_drink_rounded,
            title: 'Saisir une consommation',
            subtitle: 'Indiquez le carburant réellement utilisé sur une attribution.',
          ),
          if (_loading)
            const LoadingView()
          else
            Form(
              key: _formKey,
              child: FormLayout(
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
                    const SizedBox(width: AppSpacing.sm),
                    PrimaryButton(label: 'Enregistrer', onPressed: _submit, loading: _saving),
                  ],
                ),
                children: [
                  if (_error != null) InlineAlert(message: _error!),
                  AppDropdown<String>(
                    label: 'Attribution',
                    required: true,
                    icon: Icons.assignment_ind_outlined,
                    hint: _attributions.isEmpty ? 'Aucune attribution disponible' : 'Choisir',
                    value: _attribution,
                    items: [
                      for (final a in _attributions)
                        DropdownMenuItem(value: a['id'].toString(), child: Text(_attributionLabel(a))),
                    ],
                    onChanged: (v) => setState(() => _attribution = v),
                  ),
                  FieldRow(children: [
                    AppDropdown<String>(
                      label: 'Carburant',
                      required: true,
                      icon: Icons.local_gas_station_outlined,
                      hint: 'Choisir',
                      value: _carburant,
                      items: [
                        for (final c in _carburants)
                          DropdownMenuItem(value: c['id'].toString(), child: Text('${c['nom']}')),
                      ],
                      onChanged: (v) => setState(() => _carburant = v),
                    ),
                    AppTextField(
                      label: 'Quantité utilisée (litres)',
                      controller: _quantite,
                      required: true,
                      icon: Icons.water_drop_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        final q = double.tryParse((v ?? '').replaceAll(',', '.'));
                        return (q == null || q <= 0) ? 'Quantité invalide' : null;
                      },
                    ),
                  ]),
                  AppTextField(
                    label: 'Commentaire',
                    controller: _commentaire,
                    hint: 'Ex. mission Bobo-Dioulasso',
                    maxLines: 3,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
