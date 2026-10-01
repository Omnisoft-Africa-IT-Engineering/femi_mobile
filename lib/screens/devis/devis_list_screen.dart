import 'package:flutter/material.dart';
import '../../models/devis.dart';
import '../../models/profil_facturation.dart';
import '../../services/devis_service.dart';
import '../../utils/devis_theme.dart';
import '../../utils/format.dart';
import '../../widgets/statut_badge.dart';
import 'profil_facturation_sheet.dart';
import 'devis_chat_screen.dart';
class _Donnees {
  final ProfilFacturation? profil;
  final List<Devis> devis;
  _Donnees(this.profil, this.devis);
}

class DevisListScreen extends StatefulWidget {
  const DevisListScreen({super.key});

  @override
  State<DevisListScreen> createState() => _DevisListScreenState();
}

class _DevisListScreenState extends State<DevisListScreen> {
  final _service = DevisService.instance;
  late Future<_Donnees> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_Donnees> _charger() async {
    final r = await Future.wait<Object?>([
      _service.getProfil(),
      _service.listerDevis(),
    ]);
    return _Donnees(r[0] as ProfilFacturation?, r[1] as List<Devis>);
  }

  Future<void> _recharger() async {
    final f = _charger();
    setState(() => _futur = f);
    await f;
  }

  Future<void> _modifierProfil() async {
    final profil = await _service.getProfil();
    if (!mounted) return;
    await showProfilFacturationSheet(context, initial: profil);
  }

  Future<void> _creerDevis() async {
    var profil = await _service.getProfil();
    if (!mounted) return;
    // Premier usage : on configure l'en-tête / pied de page d'abord.
    if (profil == null || !profil.pretPourDevis) {
      final ok = await showProfilFacturationSheet(context, initial: profil);
      if (ok != true || !mounted) return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DevisChatScreen()),
    );
    _recharger();
  }

  /// Demande confirmation avant de supprimer un devis. Renvoie true si
  /// l'utilisateur confirme, false sinon (utilisé par Dismissible pour
  /// savoir s'il doit retirer la ligne ou la remettre en place).
  Future<bool> _confirmerSuppression(Devis devis) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce devis ?'),
        content: Text(
          '${devis.numeroDevis ?? 'Ce brouillon'} (${devis.clientNom}) sera '
              'définitivement supprimé. Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    return confirme ?? false;
  }

  Future<void> _supprimer(Devis devis) async {
    try {
      await _service.supprimerDevis(devis.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${devis.numeroDevis ?? 'Devis'} supprimé')),
      );
      _recharger();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la suppression, réessayez.')),
      );
      _recharger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Devis'),
        actions: [
          IconButton(
            tooltip: 'Mes informations de facturation',
            icon: const Icon(Icons.tune),
            onPressed: _modifierProfil,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kEmeraude,
        foregroundColor: Colors.white,
        onPressed: _creerDevis,
        icon: const Icon(Icons.add),
        label: const Text('Créer un devis'),
      ),
      body: FutureBuilder<_Donnees>(
        future: _futur,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Impossible de charger les devis.'),
                  const SizedBox(height: 12),
                  OutlinedButton(
                      onPressed: _recharger, child: const Text('Réessayer')),
                ],
              ),
            );
          }
          final devis = snap.data!.devis;
          return RefreshIndicator(
            onRefresh: _recharger,
            child: devis.isEmpty
                ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.description_outlined,
                    size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('Aucun devis pour le moment')),
              ],
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: devis.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final d = devis[i];
                return Dismissible(
                  key: ValueKey(d.id ?? d.numeroDevis ?? i),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmerSuppression(d),
                  onDismissed: (_) => _supprimer(d),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: _DevisTile(devis: d),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _DevisTile extends StatelessWidget {
  final Devis devis;
  const _DevisTile({required this.devis});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DevisChatScreen(devisExistant: devis)),
        ),
        title: Text(devis.clientNom,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${devis.numeroDevis ?? 'Brouillon'} • ${formatDate(devis.dateEmission)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatFcfa(devis.total),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            StatutBadge(statut: devis.statut),
          ],
        ),
      ),
    );
  }
}