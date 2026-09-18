import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service centralisé de génération de PDF pour les documents comptables.
/// Les données sont passées sous forme de List<Map<String, String>> pour
/// rester indépendant des classes de données propres à chaque écran.
class PdfExportService {
  /// Génère et ouvre l'aperçu PDF du Bilan Comptable.
  /// L'utilisateur pourra ensuite l'enregistrer, le partager ou l'imprimer
  /// depuis l'écran d'aperçu (icônes en haut à droite).
  static Future<void> exportBilan({
    required String totalAmount,
    required List<Map<String, String>> actifs,
    required List<Map<String, String>> passifs,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Bilan Comptable',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Total Bilan : $totalAmount FCFA'),
          pw.SizedBox(height: 20),
          pw.Text(
            'Actif (Emplois)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _buildSimpleTable(actifs),
          pw.SizedBox(height: 20),
          pw.Text(
            'Passif (Ressources)',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _buildSimpleTable(passifs),
        ],
      ),
    );
    await Printing.layoutPdf(
      name: 'Bilan_Comptable.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  /// Génère et ouvre l'aperçu PDF d'une balance comptable simple
  /// (Balance Générale : une seule liste de comptes).
  static Future<void> exportBalance({
    required String title,
    required List<Map<String, String>> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          _buildAccountTable(rows),
        ],
      ),
    );
    await Printing.layoutPdf(
      name: '${title.replaceAll(' ', '_')}.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  /// Génère et ouvre l'aperçu PDF de la Balance Auxiliaire
  /// (2 sections : Clients et Fournisseurs).
  static Future<void> exportBalanceAuxiliaire({
    required List<Map<String, String>> clients,
    required List<Map<String, String>> fournisseurs,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Balance Auxiliaire',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Clients',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _buildAccountTable(clients),
          pw.SizedBox(height: 20),
          pw.Text(
            'Fournisseurs',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          _buildAccountTable(fournisseurs),
        ],
      ),
    );
    await Printing.layoutPdf(
      name: 'Balance_Auxiliaire.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  /// Génère et ouvre l'aperçu PDF du Registre Journalier d'une date donnée.
  /// [ecritures] : chaque élément attend les clés 'heure', 'titre',
  /// 'categorie', 'montant' (déjà formaté avec signe + devise, ex "+ 15 000 XOF").
  static Future<void> exportRegistreJournalier({
    required String dateLabel,
    required String totalRecettes,
    required String totalDepenses,
    required List<Map<String, String>> ecritures,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Registre Journalier',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(dateLabel),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total recettes : $totalRecettes'),
              pw.Text('Total dépenses : $totalDepenses'),
            ],
          ),
          pw.SizedBox(height: 20),
          if (ecritures.isEmpty)
            pw.Text('Aucune transaction ce jour-là.')
          else
            _buildEcrituresTable(ecritures),
        ],
      ),
    );
    await Printing.layoutPdf(
      name: 'Registre_Journalier_${dateLabel.replaceAll(' ', '_')}.pdf',
      onLayout: (format) async => doc.save(),
    );
  }

  // --- Helpers de construction de tableaux PDF ---

  static pw.Widget _buildSimpleTable(List<Map<String, String>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
      },
      children: items.map((item) {
        return pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item['label'] ?? ''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item['amount'] ?? '', textAlign: pw.TextAlign.right),
            ),
          ],
        );
      }).toList(),
    );
  }

  static pw.Widget _buildAccountTable(List<Map<String, String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _headerCell('Compte'),
            _headerCell('Débit'),
            _headerCell('Crédit'),
            _headerCell('Solde'),
          ],
        ),
        ...rows.map((row) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${row['numero']}\n${row['libelle']}'),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['debit'] ?? '', textAlign: pw.TextAlign.right),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['credit'] ?? '', textAlign: pw.TextAlign.right),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['solde'] ?? '', textAlign: pw.TextAlign.right),
            ),
          ],
        )),
      ],
    );
  }

  static pw.Widget _buildEcrituresTable(List<Map<String, String>> ecritures) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _headerCell('Heure'),
            _headerCell('Titre'),
            _headerCell('Catégorie'),
            _headerCell('Montant'),
          ],
        ),
        ...ecritures.map((e) => pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e['heure'] ?? ''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e['titre'] ?? ''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e['categorie'] ?? ''),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(e['montant'] ?? '', textAlign: pw.TextAlign.right),
            ),
          ],
        )),
      ],
    );
  }

  static pw.Widget _headerCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );

  /// Génère et ouvre l'aperçu PDF du Grand Livre.
  static Future<void> exportGrandLivre({
    required String devise,
    required String totalDebit,
    required String totalCredit,
    required String soldeNet,
    required List<dynamic> comptes,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // En-tête
          pw.Text(
            'Grand Livre',
            style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text('Vue détaillée des comptes et de leurs mouvements.'),
          pw.SizedBox(height: 16),

          // Résumé des Totaux
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(children: [
                  pw.Text('TOTAL DÉBIT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text('$totalDebit $devise'),
                ]),
                pw.Column(children: [
                  pw.Text('TOTAL CRÉDIT', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text('$totalCredit $devise'),
                ]),
                pw.Column(children: [
                  pw.Text('SOLDE NET', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  pw.SizedBox(height: 4),
                  pw.Text('$soldeNet $devise'),
                ]),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Liste des comptes et leurs mouvements
          ...comptes.map((compte) {
            final String code = (compte['code'] as String?) ?? '';
            final String nom = (compte['nom'] as String?) ?? '';
            final String solde = (compte['solde']?.toString()) ?? '0';
            final List<dynamic> mouvements = (compte['mouvements'] as List<dynamic>?) ?? [];

            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 16),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // En-tête du compte
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    color: PdfColors.blueGrey50,
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('$code - $nom', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Solde : $solde $devise', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 4),

                  // Tableau des mouvements du compte
                  if (mouvements.isEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text('Aucun mouvement enregistré', style: const pw.TextStyle(color: PdfColors.grey600)),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(2),
                        1: pw.FlexColumnWidth(4),
                        2: pw.FlexColumnWidth(2),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                          children: [
                            _headerCell('Date'),
                            _headerCell('Libellé'),
                            _headerCell('Montant'),
                          ],
                        ),
                        ...mouvements.map((m) {
                          return pw.TableRow(
                            children: [
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(m['date']?.toString() ?? ''),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text(m['libelle']?.toString() ?? ''),
                              ),
                              pw.Padding(
                                padding: const pw.EdgeInsets.all(4),
                                child: pw.Text('${m['montant']} $devise', textAlign: pw.TextAlign.right),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );

    await Printing.layoutPdf(
      name: 'Grand_Livre.pdf',
      onLayout: (format) async => doc.save(),
    );
  }
}