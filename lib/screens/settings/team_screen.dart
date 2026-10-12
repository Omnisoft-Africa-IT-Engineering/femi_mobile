import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/femi_api_service.dart';
import 'employee_detail_screen.dart';

const Color _vert = Color(0xFF0D5C52);

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final FemiApiService _apiService = FemiApiService();

  late Future<List<dynamic>?> _equipeFuture;

  // id de l'employé en cours de traitement (évite le double-tap)
  String? _idEnCoursDeMaj;

  @override
  void initState() {
    super.initState();
    _chargerDonnees();
  }

  void _chargerDonnees() {
    _equipeFuture = _apiService.getEquipe();
  }

  Future<void> _rafraichir() async {
    setState(_chargerDonnees);
    await _equipeFuture;
  }

  String _fcfa(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf FCFA';
  }

  void _snack(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: erreur ? Colors.red : null),
    );
  }

  // ---------- Interrupteur actif / inactif ----------

  Future<void> _changerStatut(Map<String, dynamic> employe, bool actif) async {
    final String id = employe['utilisateur_id'].toString();
    final String nom = (employe['nom_complet'] ?? '').toString();

    if (!actif) {
      final bool? confirme = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Désactiver cet employé'),
          content: Text('$nom sera déconnecté immédiatement. Ses ventes passées sont conservées.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Désactiver'),
            ),
          ],
        ),
      );
      if (confirme != true) return;
    }

    setState(() => _idEnCoursDeMaj = id);
    final bool succes = await _apiService.changerStatutEmploye(id, actif);
    if (!mounted) return;
    setState(() => _idEnCoursDeMaj = null);

    if (succes) {
      await _rafraichir();
    } else {
      _snack('Échec de la mise à jour. Réessayez.', erreur: true);
    }
  }

  // ---------- Nouveau code ----------

  Future<void> _nouveauCode(Map<String, dynamic> employe) async {
    final String id = employe['utilisateur_id'].toString();
    final String nom = (employe['nom_complet'] ?? '').toString();

    setState(() => _idEnCoursDeMaj = id);
    final Map<String, dynamic> res = await _apiService.regenererCodeEmploye(id);
    if (!mounted) return;
    setState(() => _idEnCoursDeMaj = null);

    if (res.containsKey('error')) {
      _snack(res['error'].toString(), erreur: true);
    } else {
      await _afficherCode(res, nom);
    }
  }

  // ---------- Affichage du code (une seule fois) ----------

  Future<void> _afficherCode(Map<String, dynamic> data, String nom) async {
    final String code = (data['code_activation'] ?? '').toString();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Code d'activation"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Transmettez ce code à $nom. Il ne sera plus affiché ensuite '
                  'et reste valable 48 heures.',
            ),
            const SizedBox(height: 16),
            SelectableText(
              code,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 6,
                color: _vert,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              _snack('Code copié.');
            },
            child: const Text('Copier'),
          ),
          TextButton(
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                text: "Votre code d'activation Femi : $code (valable 48 h). "
                    "Ouvrez l'app, choisissez « Activer mon compte » et saisissez "
                    'votre e-mail et ce code.',
              ),
            ),
            child: const Text('Partager'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _vert),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Terminé'),
          ),
        ],
      ),
    );
  }

  // ---------- Ajout d'un employé ----------

  Future<void> _ajouterEmploye() async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final posteCtrl = TextEditingController();
    bool envoi = false;
    String? erreur;

    final Map<String, dynamic>? resultat = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ajouter un employé'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nomCtrl,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Le nom est obligatoire.' : null,
                  ),
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'E-mail'),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return "L'e-mail est obligatoire.";
                      if (!s.contains('@') || !s.contains('.')) return 'E-mail invalide.';
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: posteCtrl,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Rôle ou poste (facultatif)',
                      hintText: 'Ex : Serveuse, Caissier',
                    ),
                  ),
                  if (erreur != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(erreur!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: envoi ? null : () => Navigator.pop(dialogContext),
              child: const Text('Annuler'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _vert),
              onPressed: envoi
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;
                setDialogState(() {
                  envoi = true;
                  erreur = null;
                });
                final res = await _apiService.ajouterEmploye(
                  nomComplet: nomCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  poste: posteCtrl.text.trim(),
                );
                if (res.containsKey('error')) {
                  setDialogState(() {
                    envoi = false;
                    erreur = res['error'].toString();
                  });
                } else {
                  Navigator.pop(dialogContext, res);
                }
              },
              child: envoi
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );

    if (resultat != null && mounted) {
      await _afficherCode(resultat, nomCtrl.text.trim());
      if (mounted) await _rafraichir();
    }
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mon équipe')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _vert,
        foregroundColor: Colors.white,
        onPressed: _ajouterEmploye,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Ajouter un employé'),
      ),
      body: RefreshIndicator(
        onRefresh: _rafraichir,
        child: FutureBuilder<List<dynamic>?>(
          future: _equipeFuture,
          builder: (context, snapshot) {
            final bool chargement = snapshot.connectionState == ConnectionState.waiting;

            if (!chargement && snapshot.data == null) {
              return _buildErreur();
            }

            final List<dynamic> equipe = snapshot.data ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                if (chargement)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (equipe.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'Aucun employé pour le moment.\nAppuyez sur « Ajouter un employé » pour commencer.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${equipe.length} employé${equipe.length > 1 ? 's' : ''}'),
                    ),
                    ...equipe.map((brut) {
                      final employe = brut as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildEmployeCard(employe),
                      );
                    }),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildErreur() {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 8),
              const Text("Impossible de charger l'équipe."),
              const SizedBox(height: 4),
              const Text(
                'Vérifiez votre connexion et que vous êtes connecté en administrateur.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _rafraichir,
                style: FilledButton.styleFrom(backgroundColor: _vert),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmployeCard(Map<String, dynamic> employe) {
    final String id = employe['utilisateur_id'].toString();
    final String nom = (employe['nom_complet'] ?? '').toString();
    final bool actif = employe['actif'] == true;
    final bool compteActive = employe['compte_active'] == true;
    final bool enCoursDeMaj = _idEnCoursDeMaj == id;
    final String poste = (employe['poste'] ?? '').toString();
    final double ventes = (employe['ventes_jour'] as num?)?.toDouble() ?? 0;

    final Color couleur = !compteActive
        ? const Color(0xFFEA580C)
        : (actif ? const Color(0xFF059669) : const Color(0xFF64748B));
    final String statut =
    !compteActive ? "En attente d'activation" : (actif ? 'Actif' : 'Désactivé');

    return Opacity(
      opacity: actif ? 1 : 0.55, // employé désactivé : carte grisée
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        child: InkWell(
          // Un employé qui n'a pas activé son compte n'a pas encore de ventes :
          // sa fiche n'est donc pas ouvrable.
          onTap: !compteActive
              ? null
              : () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EmployeeDetailScreen(
                  employeId: id,
                  nom: nom,
                ),
              ),
            );
            if (mounted) await _rafraichir();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nom,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: couleur.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statut,
                        style: TextStyle(
                          fontSize: 11,
                          color: couleur,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  poste.isEmpty
                      ? (employe['email'] ?? '').toString()
                      : '$poste • ${employe['email'] ?? ''}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                if (compteActive) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Ventes du jour : ${_fcfa(ventes)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
                const SizedBox(height: 12),
                if (compteActive)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          actif ? 'Compte actif' : 'Compte désactivé',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      enCoursDeMaj
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : Switch(
                        activeColor: Colors.white,
                        activeTrackColor: _vert,
                        value: actif,
                        onChanged: (v) => _changerStatut(employe, v),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: OutlinedButton.icon(
                      onPressed: enCoursDeMaj ? null : () => _nouveauCode(employe),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _vert,
                        side: const BorderSide(color: _vert),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: enCoursDeMaj
                          ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.key, size: 18),
                      label: Text(enCoursDeMaj ? 'Génération...' : 'Nouveau code'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}