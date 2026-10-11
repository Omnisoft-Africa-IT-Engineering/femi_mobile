import 'package:flutter/material.dart';
import '../../models/team_models.dart';
import '../../services/team_service.dart';

const Color _vert = Color(0xFF0D5C52);
const Color _vertClair = Color(0xFFEAF6F3);
const Color _texte = Color(0xFF0F172A);
const Color _couleurVente = Color(0xFF059669);

String _nombre(double v) {
  final s = v.round().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String _fcfa(double v) => '${_nombre(v)} FCFA';

String _formatDate(DateTime d) {
  const mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${d.day} ${mois[d.month - 1]} ${d.year}';
}

DateTime _jour(DateTime d) => DateTime(d.year, d.month, d.day);

/// Une vente simulée (l'employé ne fait que des ventes, pas de dépenses).
class _Vente {
  final String id;
  final DateTime date;
  final String heure;
  final String titre;
  final double montant;
  const _Vente(this.id, this.date, this.heure, this.titre, this.montant);
}

/// Génère 4 ventes simulées dont le total du jour est EXACTEMENT [jour].
/// Les cartes du haut et la liste sont calculées à partir de ces mêmes ventes,
/// donc elles sont toujours cohérentes.
List<_Vente> _ventesSimulees(double jour, DateTime now) {
  double arrondi(double v) => (v / 100).round() * 100.0;
  final a = arrondi(jour * 0.6);
  final b = jour - a;
  final c = arrondi(jour * 0.8);
  final d = arrondi(jour * 1.2);
  final auj = _jour(now);
  final toutes = [
    _Vente('v-0004', auj, '16:20', "Vente de 2 cartons de lait", b),
    _Vente('v-0003', auj, '11:45', "Vente de 3 bidons d'huile", a),
    _Vente('v-0002', auj.subtract(const Duration(days: 1)), '15:10',
        'Vente de 10 sacs de riz', c),
    _Vente('v-0001', auj.subtract(const Duration(days: 8)), '10:05',
        'Vente de 5 paquets de sucre', d),
  ];
  return toutes.where((v) => v.montant > 0).toList();
}

double _somme(Iterable<_Vente> ventes, DateTime debut, DateTime fin) {
  final d = _jour(debut);
  final f = _jour(fin);
  var total = 0.0;
  for (final v in ventes) {
    final j = _jour(v.date);
    if (!j.isBefore(d) && !j.isAfter(f)) total += v.montant;
  }
  return total;
}

/// Fiche d'un employé : trois cartes de ventes en haut, sélecteur de dates,
/// puis registre des ventes en bas. Tout est SIMULÉ pour l'instant.
class EmployeeDetailScreen extends StatefulWidget {
  final String memberId;
  const EmployeeDetailScreen({super.key, required this.memberId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  late DateTimeRange _periode;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _periode = DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
  }

  Future<void> _choisirDates() async {
    final now = DateTime.now();
    final nouvelle = await showDateRangePicker(
      context: context,
      initialDateRange: _periode,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF006654),
            onPrimary: Colors.white,
            onSurface: _texte,
          ),
        ),
        child: child!,
      ),
    );
    if (nouvelle != null && nouvelle != _periode) {
      setState(() => _periode = nouvelle);
    }
  }

  Future<void> _editPoste(TeamMember m) async {
    final ctrl = TextEditingController(text: m.poste);
    final nouveau = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Rôle de ${m.nom}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Rôle ou poste',
            hintText: 'Ex : Serveuse, Employé 1, Caissier',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _vert),
            onPressed: () => Navigator.pop(dialogContext, ctrl.text),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    if (nouveau != null) {
      await TeamService.instance.updatePoste(m.id, nouveau);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = TeamService.instance;
    return ListenableBuilder(
      listenable: service,
      builder: (context, _) {
        TeamMember? trouve;
        for (final x in service.members) {
          if (x.id == widget.memberId) {
            trouve = x;
            break;
          }
        }
        if (trouve == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Fiche employé')),
            body: const Center(child: Text('Employé introuvable.')),
          );
        }
        final m = trouve;

        // ----- Ventes simulées + chiffres cohérents -----
        final now = DateTime.now();
        final ventes = _ventesSimulees(m.ventesDuJour, now);
        final debutSemaine = _jour(now).subtract(Duration(days: now.weekday - 1));
        final debutMois = DateTime(now.year, now.month, 1);
        final totalJour = _somme(ventes, now, now);
        final totalSemaine = _somme(ventes, debutSemaine, now);
        final totalMois = _somme(ventes, debutMois, now);

        // ----- Liste filtrée par la période choisie -----
        final d = _jour(_periode.start);
        final f = _jour(_periode.end);
        final affichees = ventes.where((v) {
          final j = _jour(v.date);
          return !j.isBefore(d) && !j.isAfter(f);
        }).toList();
        final totalPeriode =
        affichees.fold<double>(0, (s, v) => s + v.montant);

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FE),
          appBar: AppBar(
            title: const Text('Fiche employé'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'role') _editPoste(m);
                  if (v == 'actif') service.setActif(m.id, !m.actif);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'role',
                    child: Text('Modifier le rôle'),
                  ),
                  PopupMenuItem(
                    value: 'actif',
                    child: Text(m.actif
                        ? 'Désactiver le compte'
                        : 'Réactiver le compte'),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ---------- En-tête ----------
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: _vertClair,
                    foregroundColor: _vert,
                    child: Text(
                      m.nom.isEmpty ? '?' : m.nom[0].toUpperCase(),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.nom,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${m.poste} • ${m.actif ? 'Actif' : 'Désactivé'}',
                          style: TextStyle(
                              color: m.actif ? _vert : Colors.grey),
                        ),
                        Text(
                          m.contact,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ---------- Trois cartes ----------
              Row(
                children: [
                  Expanded(
                      child: _StatCard(
                          label: "Aujourd'hui", valeur: totalJour)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(
                          label: 'Cette semaine', valeur: totalSemaine)),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _StatCard(label: 'Ce mois', valeur: totalMois)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Données simulées pour le moment.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),

              // ---------- Titre + sélecteur de dates ----------
              const Text(
                'Registre des ventes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _texte,
                ),
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: _choisirDates,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.date_range_outlined,
                                color: Color(0xFF006654), size: 22),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                '${_formatDate(_periode.start)} — ${_formatDate(_periode.end)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _texte,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_calendar,
                          color: Color(0xFF64748B), size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Total des ventes sur la période : ${_fcfa(totalPeriode)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _vert,
                ),
              ),
              const SizedBox(height: 12),

              // ---------- Liste des ventes ----------
              if (affichees.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Aucune vente enregistrée pour cette période.',
                      style: TextStyle(color: Colors.black45),
                    ),
                  ),
                )
              else
                ...affichees.map((v) => _VenteTile(vente: v)),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final double valeur;
  const _StatCard({required this.label, required this.valeur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: _vertClair,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _vert, fontSize: 12),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _nombre(valeur),
              style: const TextStyle(
                color: _vert,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
          ),
          const Text('FCFA', style: TextStyle(color: _vert, fontSize: 11)),
        ],
      ),
    );
  }
}

class _VenteTile extends StatelessWidget {
  final _Vente vente;
  const _VenteTile({required this.vente});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDate(vente.date),
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  vente.heure,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            vente.titre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _texte,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: _couleurVente, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text('Vente',
                    style: TextStyle(color: Color(0xFF475569))),
              ),
              Text(
                '+ ${_fcfa(vente.montant)}',
                style: const TextStyle(
                  color: _couleurVente,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}