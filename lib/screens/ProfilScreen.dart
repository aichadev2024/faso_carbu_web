import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../core/config/app_config.dart';
import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../core/widgets/logo.dart';
import '../core/theme/app_colors.dart';
import 'main_layout.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key, required this.jwtToken, required this.userId});
  final String jwtToken;
  final String userId;

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;
  bool _uploading = false;
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
        Uri.parse('${AppConfig.apiUrl}/utilisateurs/${widget.userId}'),
        headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
      );
      if (res.statusCode != 200) throw Exception(res.statusCode);
      if (mounted) setState(() => _user = jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger votre profil.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _changePhoto() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked == null) return;
    setState(() => _uploading = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${AppConfig.apiUrl}/utilisateurs/${widget.userId}/upload-photo'))
        ..headers['Authorization'] = 'Bearer ${widget.jwtToken}'
        ..files.add(http.MultipartFile.fromBytes('file', await picked.readAsBytes(), filename: picked.name));
      final res = await request.send();
      if (res.statusCode != 200) throw Exception(res.statusCode);
      final data = jsonDecode(await res.stream.bytesToString());
      if (!mounted) return;
      setState(() => _user = {...?_user, 'photoProfil': '${data['photoProfil']}?t=${DateTime.now().millisecondsSinceEpoch}'});
      showAppSnack(context, 'Photo de profil mise à jour.', tone: Tone.success);
    } catch (_) {
      if (mounted) showAppSnack(context, 'Envoi de la photo impossible.', tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String? get _photoUrl {
    final p = (_user?['photoProfil'] ?? _user?['photoUrl'])?.toString();
    if (p == null || p.isEmpty) return null;
    return p.startsWith('http') ? p : '${AppConfig.backendUrl}$p';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final u = _user ?? {};
    final fullName = '${u['prenom'] ?? Session.prenom} ${u['nom'] ?? Session.nom}'.trim();
    final entreprise = u['entreprise'] is Map ? u['entreprise'] as Map : null;

    Widget info(IconData icon, String label, String? value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: t.bodySmall?.color),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 140, child: Text(label, style: t.bodyMedium)),
          Expanded(child: Text((value ?? '').isEmpty ? '—' : value!, style: t.titleSmall)),
        ],
      ),
    );

    return MainLayout(
      title: 'Mon profil',
      jwtToken: widget.jwtToken,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(
            eyebrow: 'Mon compte',
            icon: Icons.person_rounded,
            title: 'Mon profil',
            subtitle: 'Vos informations personnelles et la sécurité de votre compte.',
          ),
          if (_loading)
            const LoadingView()
          else if (_error != null)
            Card(
              child: ErrorState(message: _error!, onRetry: _load),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Bandeau aux couleurs de la marque au-dessus de l'identité.
                        Container(
                          height: 96,
                          decoration: const BoxDecoration(gradient: inkGradient),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -40,
                                top: -60,
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [AppColors.brand.withValues(alpha: 0.5), AppColors.brand.withValues(alpha: 0)],
                                    ),
                                  ),
                                ),
                              ),
                              const Positioned(
                                right: 24,
                                bottom: -18,
                                child: Opacity(opacity: 0.12, child: LogoMark(size: 90, withBackground: false, color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xl),
                          child: Wrap(
                            spacing: AppSpacing.xl,
                            runSpacing: AppSpacing.lg,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  InitialsAvatar(name: fullName, size: 88, imageUrl: _photoUrl),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Material(
                                      color: Theme.of(context).colorScheme.primary,
                                      shape: const CircleBorder(),
                                      child: InkWell(
                                        customBorder: const CircleBorder(),
                                        onTap: _uploading ? null : _changePhoto,
                                        child: Padding(
                                          padding: const EdgeInsets.all(7),
                                          child: _uploading
                                              ? const SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                )
                                              : const Icon(Icons.photo_camera_outlined, size: 16, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(fullName, style: t.headlineSmall),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text('${u['email'] ?? Session.email}', style: t.bodyMedium),
                                  const SizedBox(height: AppSpacing.sm),
                                  StatusBadge(label: Session.roleLabelOf('${u['role'] ?? Session.role}'), tone: Tone.brand),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    title: 'Informations',
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                    child: Column(
                      children: [
                        info(Icons.person_outline_rounded, 'Nom complet', fullName),
                        info(Icons.alternate_email_rounded, 'Identifiant', u['nomUtilisateur']?.toString()),
                        info(Icons.mail_outline_rounded, 'Email', u['email']?.toString()),
                        info(Icons.phone_outlined, 'Téléphone', u['telephone']?.toString()),
                        info(Icons.business_outlined, 'Entreprise', entreprise?['nom']?.toString()),
                        info(Icons.event_outlined, 'Membre depuis', formatDate(DateTime.tryParse('${u['dateCreation'] ?? ''}'))),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    title: 'Sécurité',
                    subtitle: 'Changez régulièrement votre mot de passe.',
                    trailing: OutlinedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/change-password', arguments: Session.routeArgs),
                      icon: const Icon(Icons.lock_reset_rounded, size: 18),
                      label: const Text('Changer le mot de passe'),
                    ),
                    padding: EdgeInsets.zero,
                    child: const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
