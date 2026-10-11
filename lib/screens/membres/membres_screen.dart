import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';

class MembresScreen extends StatefulWidget {
  const MembresScreen({super.key});

  @override
  State<MembresScreen> createState() => _MembresScreenState();
}

class _MembresScreenState extends State<MembresScreen> {
  final FemiApiService _api = FemiApiService();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _membres = [];

  static const List<String> _roles = [
    'admin',
    'comptable',
    'employe',
    'lecteur',
  ];

  @override
  void initState() {
    super.initState();
    _chargerMembres();
  }

  Future<void> _chargerMembres() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = await _api.getMembres();

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger les membres.';
        _membres = [];
      });
      return;
    }

    setState(() {
      _loading = false;
      _membres = data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    });
  }

  String _labelRole(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'comptable':
        return 'Comptable';
      case 'employe':
        return 'Employé';
      case 'lecteur':
        return 'Lecteur';
      default:
        return role?.isNotEmpty == true ? role! : 'Sans rôle';
    }
  }

  Color _couleurRole(String? role) {
    switch ((role ?? '').toLowerCase()) {
      case 'admin':
        return const Color(0xFF006654);
      case 'comptable':
        return const Color(0xFF1B75BC);
      case 'employe':
        return Colors.orange.shade700;
      case 'lecteur':
        return Colors.grey.shade700;
      default:
        return Colors.grey;
    }
  }

  Future<void> _ouvrirAjouterMembre() async {
    final emailCtrl = TextEditingController();
    String roleChoisi = 'comptable';

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ajouter un membre',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'L’utilisateur doit déjà avoir un compte Femi.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: roleChoisi,
                    decoration: const InputDecoration(
                      labelText: 'Rôle',
                      border: OutlineInputBorder(),
                    ),
                    items: _roles
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(_labelRole(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setModalState(() => roleChoisi = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF006654),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Ajouter'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );

    if (ok != true) return;

    final email = emailCtrl.text.trim();
    if (email.isEmpty) {
      _snack('Email requis.', isError: true);
      return;
    }

    final result = await _api.ajouterMembre(email: email, role: roleChoisi);

    if (!mounted) return;

    if (result == null || result['error'] == true) {
      _snack(
        result?['message']?.toString() ?? 'Impossible d’ajouter le membre.',
        isError: true,
      );
      return;
    }

    _snack('Membre ajouté.');
    await _chargerMembres();
  }

  Future<void> _changerRole(Map<String, dynamic> membre) async {
    final membreId = membre['id']?.toString();
    if (membreId == null) return;

    String roleChoisi = (membre['role'] ?? 'employe').toString().toLowerCase();
    if (!_roles.contains(roleChoisi)) {
      roleChoisi = 'employe';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Modifier le rôle'),
          content: DropdownButtonFormField<String>(
            value: roleChoisi,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            items: _roles
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(_labelRole(r)),
                  ),
                )
                .toList(),
            onChanged: (v) {
              if (v != null) roleChoisi = v;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final result = await _api.modifierRoleMembre(
      membreId: membreId,
      role: roleChoisi,
    );

    if (!mounted) return;

    if (result == null || result['error'] == true) {
      _snack(
        result?['message']?.toString() ?? 'Impossible de modifier le rôle.',
        isError: true,
      );
      return;
    }

    _snack('Rôle mis à jour.');
    await _chargerMembres();
  }

  Future<void> _retirerMembre(Map<String, dynamic> membre) async {
    final membreId = membre['id']?.toString();
    if (membreId == null) return;

    final nom = membre['full_name']?.toString() ??
        membre['email']?.toString() ??
        'ce membre';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Retirer le membre'),
          content: Text(
            'Retirer $nom de l’entreprise ?\n'
            'Son compte Femi ne sera pas supprimé.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Retirer'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    final success = await _api.supprimerMembre(membreId);

    if (!mounted) return;

    if (!success) {
      _snack('Impossible de retirer le membre.', isError: true);
      return;
    }

    _snack('Membre retiré.');
    await _chargerMembres();
  }

  void _snack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF006654),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Membres de l’entreprise',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _chargerMembres,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirAjouterMembre,
        backgroundColor: const Color(0xFF006654),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _chargerMembres,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _membres.isEmpty
                  ? const Center(
                      child: Text('Aucun membre pour le moment.'),
                    )
                  : RefreshIndicator(
                      onRefresh: _chargerMembres,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: _membres.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final m = _membres[index];
                          final role = m['role']?.toString();
                          final name = m['full_name']?.toString().isNotEmpty == true
                              ? m['full_name'].toString()
                              : (m['email']?.toString() ?? 'Membre');
                          final email = m['email']?.toString() ?? '';

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor:
                                    _couleurRole(role).withValues(alpha: 0.15),
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    color: _couleurRole(role),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(email),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _couleurRole(role)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _labelRole(role),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _couleurRole(role),
                                      ),
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'role') {
                                        _changerRole(m);
                                      } else if (value == 'delete') {
                                        _retirerMembre(m);
                                      }
                                    },
                                    itemBuilder: (_) => const [
                                      PopupMenuItem(
                                        value: 'role',
                                        child: Text('Modifier le rôle'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          'Retirer',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}