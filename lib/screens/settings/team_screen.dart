import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/team_models.dart';
import '../../services/team_service.dart';
import 'employee_detail_screen.dart';

const Color _vert = Color(0xFF0D5C52);
const Color _vertClair = Color(0xFFEAF6F3);

String _fcfa(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '$buf FCFA';
}

/// Mot de passe aléatoire généré en arrière-plan (le gérant n'en saisit plus).
/// À remplacer : le backend devra générer et envoyer l'accès à l'employé.
String _motDePasseTemporaire() {
  const c = 'abcdefghjkmnpqrstuvwxyz23456789';
  final r = Random.secure();
  return List.generate(8, (_) => c[r.nextInt(c.length)]).join();
}

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _AddMemberSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = TeamService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Mon équipe')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _vert,
        foregroundColor: Colors.white,
        onPressed: () => _openAddSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter un employé'),
      ),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final members = service.members;
          if (members.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucun employé pour le moment.\nAppuyez sur « Ajouter un employé » pour commencer.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 90),
            itemCount: members.length + 1,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    '${members.length} employé${members.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }
              final m = members[i - 1];
              return ListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EmployeeDetailScreen(memberId: m.id),
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: _vertClair,
                  foregroundColor: _vert,
                  child: Text(m.nom.isEmpty ? '?' : m.nom[0].toUpperCase()),
                ),
                title: Text(
                  m.nom,
                  style: TextStyle(color: m.actif ? null : Colors.grey),
                ),
                subtitle: Text(
                  m.actif
                      ? '${m.poste} • Ventes du jour : ${_fcfa(m.ventesDuJour)}'
                      : '${m.poste} • Désactivé',
                ),
                trailing: Switch(
                  activeColor: Colors.white,
                  activeTrackColor: _vert,
                  value: m.actif,
                  onChanged: (v) => service.setActif(m.id, v),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AddMemberSheet extends StatefulWidget {
  const _AddMemberSheet();

  @override
  State<_AddMemberSheet> createState() => _AddMemberSheetState();
}

class _AddMemberSheetState extends State<_AddMemberSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _contact = TextEditingController();
  final _poste = TextEditingController();
  bool _loading = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _contact.dispose();
    _poste.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erreur = null;
    });
    try {
      await TeamService.instance.addMember(
        nom: _nom.text,
        contact: _contact.text,
        motDePasse: _motDePasseTemporaire(),
        poste: _poste.text,
      );
      if (!mounted) return;
      final nom = _nom.text.trim();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text('$nom a été ajouté(e) à l\'équipe.')));
    } on TeamException catch (e) {
      setState(() => _erreur = e.message);
    } catch (_) {
      setState(() => _erreur = 'Une erreur est survenue. Vérifiez votre connexion.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Garde le bouton au-dessus de la barre système ET du clavier.
    final media = MediaQuery.of(context);
    final bas = media.viewInsets.bottom > media.viewPadding.bottom
        ? media.viewInsets.bottom
        : media.viewPadding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bas + 16),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Ajouter un employé',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                    labelText: 'Nom complet', border: OutlineInputBorder()),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contact,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'E-mail ou téléphone', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Le contact est obligatoire.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _poste,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Rôle ou poste (facultatif)',
                  hintText: 'Ex : Serveuse, Employé 1, Caissier',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 12),
                Text(_erreur!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _vert),
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Ajouter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}