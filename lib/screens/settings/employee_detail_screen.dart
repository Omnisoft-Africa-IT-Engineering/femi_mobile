import 'package:flutter/material.dart';
import '../../services/femi_api_service.dart';

const Color _vert = Color(0xFF006654);
const Color _fond = Color(0xFFF8F9FE);
const Color _encre = Color(0xFF0F172A);

/// Fiche d'un employé : infos, totaux (aujourd'hui / semaine / mois)
/// et registre des ventes avec exercice + plage de dates.
class EmployeeDetailScreen extends StatefulWidget {
  final String employeId;
  final String nom;

  const EmployeeDetailScreen({
    super.key,
    required this.employeId,
    required this.nom,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final FemiApiService _apiService = FemiApiService();

  late Future<Map<String, dynamic>?> _ficheFuture;
  late Future<Map<String, dynamic>?> _registreFuture;

  late int _exerciceSelectionne;
  late DateTimeRange _periodeSelectionnee;

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _exerciceSelectionne = now.year;
    // Par défaut : du 1er du mois jusqu'à aujourd'hui
    _periodeSelectionnee = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: now,
    );
    _ficheFuture = _apiService.getFicheEmploye(widget.employeId);
    _chargerRegistre();
  }

  void _chargerRegistre() {
    final DateTime fin = _periodeSelectionnee.end;
    _registreFuture = _apiService.getRegistreEmploye(
      widget.employeId,
      debut: _periodeSelectionnee.start,
      // fin de journée, pour inclure les ventes du dernier jour choisi
      fin: DateTime(fin.year, fin.month, fin.day, 23, 59, 59),
    );
  }

  Future<void> _rafraichir() async {
    setState(() {
      _ficheFuture = _apiService.getFicheEmploye(widget.employeId);
      _chargerRegistre();
    });
    await _registreFuture;
  }

  // ---------- Exercice et dates ----------

  void _changerExercice(int nouvelExercice) {
    setState(() {
      _exerciceSelectionne = nouvelExercice;
      final DateTime now = DateTime.now();
      if (nouvelExercice == now.year) {
        _periodeSelectionnee = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: now,
        );
      } else {
        _periodeSelectionnee = DateTimeRange(
          start: DateTime(nouvelExercice, 1, 1),
          end: DateTime(nouvelExercice, 12, 31),
        );
      }
      _chargerRegistre();
    });
  }

  Future<void> _selectionnerPlageDates() async {
    final DateTimeRange? nouvellePlage = await showDateRangePicker(
      context: context,
      initialDateRange: _periodeSelectionnee,
      firstDate: DateTime(_exerciceSelectionne, 1, 1),
      lastDate: DateTime(_exerciceSelectionne, 12, 31),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _vert,
              onPrimary: Colors.white,
              onSurface: _encre,
            ),
          ),
          child: child!,
        );
      },
    );

    if (nouvellePlage != null && nouvellePlage != _periodeSelectionnee) {
      setState(() {
        _periodeSelectionnee = nouvellePlage;
        _chargerRegistre();
      });
    }
  }

  /// Appui sur une des trois cartes : applique la période correspondante.
  void _appliquerPeriode(String cle) {
    final DateTime now = DateTime.now();
    final DateTime aujourdhui = DateTime(now.year, now.month, now.day);
    late DateTime debut;
    switch (cle) {
      case 'aujourdhui':
        debut = aujourdhui;
        break;
      case 'semaine': // la semaine commence le lundi
        debut = aujourdhui.subtract(Duration(days: now.weekday - 1));
        break;
      default:
        debut = DateTime(now.year, now.month, 1);
    }
    setState(() {
      _exerciceSelectionne = now.year;
      _periodeSelectionnee = DateTimeRange(start: debut, end: now);
      _chargerRegistre();
    });
  }

  // ---------- Formats ----------

  String _formatDate(DateTime date) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }

  String _formatPlageDates(DateTimeRange plage) {
    return '${_formatDate(plage.start)} — ${_formatDate(plage.end)}';
  }

  String _montant(num v, String devise) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '$buf ${devise == 'XOF' ? 'FCFA' : devise}';
  }

  // ---------- Interface ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _fond,
      appBar: AppBar(
        backgroundColor: _fond,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _encre, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.nom,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _encre,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _rafraichir,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            children: [
              _buildFiche(),
              const SizedBox(height: 20),
              const Text(
                'Registre des ventes',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _encre,
                ),
              ),
              const SizedBox(height: 16),
              _SelecteurExercice(
                exerciceSelectionne: _exerciceSelectionne,
                onExerciceChange: _changerExercice,
              ),
              const SizedBox(height: 12),
              _buildSelecteurDates(),
              const SizedBox(height: 20),
              _buildRegistre(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Fiche : infos + 3 cartes de totaux ----------

  Widget _buildFiche() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _ficheFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final fiche = snapshot.data;
        if (fiche == null) {
          return const Text(
            'Impossible de charger la fiche.',
            style: TextStyle(color: Colors.red),
          );
        }

        final String devise = (fiche['devise'] ?? 'XOF').toString();
        final ventes = (fiche['ventes'] ?? {}) as Map<String, dynamic>;
        final String poste = (fiche['poste'] ?? '').toString();
        final String email = (fiche['email'] ?? '').toString();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (fiche['nom_complet'] ?? widget.nom).toString(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _encre,
                    ),
                  ),
                  if (poste.isNotEmpty)
                    Text(poste, style: const TextStyle(color: Color(0xFF64748B))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.email_outlined,
                          size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          email,
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _carteTotal(
                    "AUJOURD'HUI",
                    _montant((ventes['aujourdhui'] as num?) ?? 0, devise),
                    'aujourdhui',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _carteTotal(
                    'CETTE SEMAINE',
                    _montant((ventes['semaine'] as num?) ?? 0, devise),
                    'semaine',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _carteTotal(
                    'CE MOIS',
                    _montant((ventes['mois'] as num?) ?? 0, devise),
                    'mois',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _carteTotal(String titre, String montant, String cle) {
    return InkWell(
      onTap: () => _appliquerPeriode(cle),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFE0EBFF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                montant,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _encre,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Sélecteur de plage de dates ----------

  Widget _buildSelecteurDates() {
    return InkWell(
      onTap: _selectionnerPlageDates,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  const Icon(Icons.date_range_outlined, color: _vert, size: 22),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      _formatPlageDates(_periodeSelectionnee),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _encre,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_calendar, color: Color(0xFF64748B), size: 18),
          ],
        ),
      ),
    );
  }

  // ---------- Registre ----------

  Widget _buildRegistre() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _registreFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        if (data == null) {
          return const Text(
            'Impossible de charger le registre.',
            style: TextStyle(color: Colors.red),
          );
        }

        final String devise = (data['devise'] ?? 'XOF').toString();
        final List ecritures = (data['ecritures'] ?? []) as List;
        final num total = (data['total_recettes'] as num?) ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0EBFF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL DES VENTES',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _montant(total, devise),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _encre,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (ecritures.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'Aucune vente sur cette période.',
                    style: TextStyle(color: Colors.black45),
                  ),
                ),
              )
            else
              ...ecritures.map((brut) {
                final e = brut as Map<String, dynamic>;
                final String id = (e['id'] ?? '').toString();
                final double montant = (e['montant'] as num?)?.toDouble() ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CarteVente(
                    id: id.length > 8 ? id.substring(0, 8) : id,
                    heure: (e['heure'] ?? '').toString(),
                    titre: (e['titre'] ?? '').toString(),
                    categorie: (e['categorie'] ?? 'Recette').toString(),
                    montant: '+ ${_montant(montant, devise)}',
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}


// ============================================================
// Widgets internes (pas besoin de fichiers externes)
// ============================================================

class _SelecteurExercice extends StatelessWidget {
  final int exerciceSelectionne;
  final ValueChanged<int> onExerciceChange;

  const _SelecteurExercice({
    required this.exerciceSelectionne,
    required this.onExerciceChange,
  });

  @override
  Widget build(BuildContext context) {
    final int annee = DateTime.now().year;
    final List<int> annees = [for (int a = annee; a >= annee - 5; a--) a];

    return PopupMenuButton<int>(
      onSelected: onExerciceChange,
      itemBuilder: (_) => annees
          .map((a) => PopupMenuItem<int>(value: a, child: Text('$a')))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 20, color: Color(0xFF64748B)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Exercice',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Text(
              '$exerciceSelectionne',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _encre,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: _encre),
          ],
        ),
      ),
    );
  }
}

class _CarteVente extends StatelessWidget {
  final String id;
  final String heure;
  final String titre;
  final String categorie;
  final String montant;

  const _CarteVente({
    required this.id,
    required this.heure,
    required this.titre,
    required this.categorie,
    required this.montant,
  });

  @override
  Widget build(BuildContext context) {
    const Color vert = Color(0xFF059669);
    return Container(
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
              Text(id,
                  style: const TextStyle(
                      fontSize: 13, color: Color(0xFF64748B))),
              if (heure.isNotEmpty)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(heure,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF475569))),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            titre,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _encre,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration:
                const BoxDecoration(color: vert, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(categorie,
                    style: const TextStyle(color: Color(0xFF334155))),
              ),
              Text(
                montant,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: vert),
              ),
            ],
          ),
        ],
      ),
    );
  }
}