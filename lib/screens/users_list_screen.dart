import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/session.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/app_widgets.dart';
import '../models/role.dart' as role_model;
import '../models/user.dart';
import '../providers/user_provider.dart';
import 'main_layout.dart';
import 'user_form_screen.dart';

class UsersListScreen extends StatefulWidget {
  const UsersListScreen({super.key});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  String _search = '';
  role_model.Role? _roleFilter;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      await context.read<UserProvider>().loadUsers();
    } catch (_) {
      if (mounted) setState(() => _error = 'Impossible de charger les utilisateurs.');
    }
  }

  List<User> _visible(List<User> all) {
    final q = _search.toLowerCase();
    return all.where((u) {
      if (_roleFilter != null && u.role != _roleFilter) return false;
      if (q.isEmpty) return true;
      return '${u.prenom} ${u.nom} ${u.email} ${u.telephone}'.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _openForm([User? existing]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/users/form'),
        builder: (_) => UserFormScreen(existing: existing),
      ),
    );
    if (saved == true && mounted) _load();
  }

  Future<void> _delete(User u) async {
    final ok = await confirmDialog(
      context,
      title: 'Supprimer ${u.prenom} ${u.nom} ?',
      message: 'Ce compte n\'aura plus accès à FasoCarbu. Cette action est définitive.',
      confirmLabel: 'Supprimer',
      destructive: true,
    );
    if (!ok || !mounted) return;
    try {
      await context.read<UserProvider>().removeUser(u.id!);
      if (mounted) showAppSnack(context, 'Utilisateur supprimé.', tone: Tone.success);
    } catch (_) {
      if (mounted) showAppSnack(context, 'La suppression a échoué.', tone: Tone.danger);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<UserProvider>();
    final visible = _visible(provider.users);

    return MainLayout(
      title: 'Utilisateurs',
      jwtToken: Session.token,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Utilisateurs',
            subtitle: 'Demandeurs, chauffeurs et personnel de station de votre entreprise.',
            actions: [
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.person_add_alt_rounded, size: 18),
                label: const Text('Ajouter un utilisateur'),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SearchField(hint: 'Nom, email, téléphone…', onChanged: (v) => setState(() => _search = v)),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<role_model.Role?>(
                  value: _roleFilter,
                  isExpanded: true,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_list_rounded, size: 20)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tous les rôles')),
                    for (final r in role_model.Role.values)
                      DropdownMenuItem(value: r, child: Text(Session.roleLabelOf(r.name))),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            clipBehavior: Clip.antiAlias,
            child: provider.loading && provider.users.isEmpty
                ? const LoadingView()
                : _error != null
                    ? ErrorState(message: _error!, onRetry: _load)
                    : visible.isEmpty
                        ? EmptyState(
                            icon: Icons.group_outlined,
                            title: provider.users.isEmpty ? 'Aucun utilisateur' : 'Aucun résultat',
                            message: provider.users.isEmpty
                                ? 'Ajoutez les membres de votre entreprise pour qu\'ils puissent utiliser FasoCarbu.'
                                : 'Modifiez la recherche ou le filtre.',
                            action: provider.users.isEmpty
                                ? FilledButton(onPressed: () => _openForm(), child: const Text('Ajouter un utilisateur'))
                                : null,
                          )
                        : AppDataTable(
                            columns: const [
                              DataColumn(label: Text('UTILISATEUR')),
                              DataColumn(label: Text('RÔLE')),
                              DataColumn(label: Text('TÉLÉPHONE')),
                              DataColumn(label: Text('STATUT')),
                              DataColumn(label: Text('')),
                            ],
                            rows: [
                              for (final u in visible)
                                DataRow(cells: [
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    InitialsAvatar(name: '${u.prenom} ${u.nom}', size: 32),
                                    const SizedBox(width: AppSpacing.md),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('${u.prenom} ${u.nom}', style: Theme.of(context).textTheme.titleSmall),
                                        Text(u.email, style: Theme.of(context).textTheme.bodySmall),
                                      ],
                                    ),
                                  ])),
                                  DataCell(StatusBadge(label: Session.roleLabelOf(u.role.name), tone: _roleTone(u.role))),
                                  DataCell(Text(u.telephone.isEmpty ? '—' : u.telephone)),
                                  DataCell(StatusBadge(
                                    label: u.actif ? 'Actif' : 'Inactif',
                                    tone: u.actif ? Tone.success : Tone.neutral,
                                  )),
                                  DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(
                                      tooltip: 'Modifier',
                                      icon: const Icon(Icons.edit_outlined, size: 20),
                                      onPressed: () => _openForm(u),
                                    ),
                                    IconButton(
                                      tooltip: 'Supprimer',
                                      icon: Icon(Icons.delete_outline_rounded, size: 20, color: Tone.danger.fg),
                                      onPressed: () => _delete(u),
                                    ),
                                  ])),
                                ]),
                            ],
                          ),
          ),
        ],
      ),
    );
  }

  Tone _roleTone(role_model.Role r) => switch (r) {
        role_model.Role.GESTIONNAIRE => Tone.brand,
        role_model.Role.CHAUFFEUR => Tone.info,
        role_model.Role.ADMIN_STATION || role_model.Role.AGENT_STATION => Tone.success,
        _ => Tone.neutral,
      };
}
