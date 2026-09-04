import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Service centralisé de génération de PDF pour les documents comptables.
class PdfExportService {
  static Future<void> exportBilan({
    required String totalAmount,
    required List<Map<String, String>> actifs,
    required List<Map<String, String>> passifs,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Bilan Comptable',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Total Bilan : $totalAmount FCFA'),
          pw.SizedBox(height: 20),
          pw.Text('Actif (Emplois)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(actifs),
          pw.SizedBox(height: 20),
          pw.Text('Passif (Ressources)',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(passifs),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Bilan_Comptable.pdf', onLayout: (format) async => doc.save());
  }

  static Future<void> exportBalance({
    required String title,
    required List<Map<String, String>> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(title,
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
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

  static Future<void> exportBalanceAuxiliaire({
    required List<Map<String, String>> clients,
    required List<Map<String, String>> fournisseurs,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Balance Auxiliaire',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text('Clients',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildAccountTable(clients),
          pw.SizedBox(height: 20),
          pw.Text('Fournisseurs',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildAccountTable(fournisseurs),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Balance_Auxiliaire.pdf', onLayout: (format) async => doc.save());
  }

  static Future<void> exportGrandLivre({
    required String totalDebit,
    required String totalCredit,
    required String soldeNet,
    required List<Map<String, dynamic>> comptes,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Grand Livre',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Text(
              'Total Débit : $totalDebit   |   Total Crédit : $totalCredit   |   Solde Net : $soldeNet'),
          pw.SizedBox(height: 20),
          ...comptes.expand((compte) => [
            pw.Text('${compte['code']} — ${compte['nom']} (Solde : ${compte['solde']})',
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            _buildMouvementsTable(
                List<Map<String, dynamic>>.from(compte['mouvements'] ?? [])),
            pw.SizedBox(height: 16),
          ]),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Grand_Livre.pdf', onLayout: (format) async => doc.save());
  }

  static Future<void> exportRegistreJournalier({
    required String dateText,
    required String totalDebit,
    required String totalCredit,
    required List<Map<String, dynamic>> ecritures,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Registre Journalier',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(dateText),
          pw.SizedBox(height: 8),
          pw.Text('Total Débit : $totalDebit   |   Total Crédit : $totalCredit'),
          pw.SizedBox(height: 20),
          ...ecritures.expand((ecriture) {
            final lines = List<Map<String, dynamic>>.from(ecriture['lines'] ?? []);
            final bottomLine = ecriture['bottomLine'] as Map<String, dynamic>?;
            final allLines = [...lines, if (bottomLine != null) bottomLine];
            return [
              pw.Text('${ecriture['id']} — ${ecriture['title']} (${ecriture['time']})',
                  style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              _buildEcritureLinesTable(allLines),
              pw.SizedBox(height: 16),
            ];
          }),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Registre_Journalier.pdf', onLayout: (format) async => doc.save());
  }

  /// Génère le PDF du Compte de Résultat (Produits / Charges / Résultat net).
  static Future<void> exportCompteResultat({
    required String resultatNet,
    required List<Map<String, String>> produits,
    required List<Map<String, String>> charges,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Compte de Résultat',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Résultat Net : $resultatNet FCFA'),
          pw.SizedBox(height: 20),
          pw.Text('Produits',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(produits),
          pw.SizedBox(height: 20),
          pw.Text('Charges',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(charges),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Compte_de_Resultat.pdf', onLayout: (format) async => doc.save());
  }

  /// Génère le PDF du TAFIRE (Ressources / Emplois de trésorerie).
  static Future<void> exportTafire({
    required String variationTresorerie,
    required List<Map<String, String>> ressources,
    required List<Map<String, String>> emplois,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('TAFIRE — Tableau Financier des Ressources et Emplois',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Variation de trésorerie : $variationTresorerie FCFA'),
          pw.SizedBox(height: 20),
          pw.Text('Ressources',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(ressources),
          pw.SizedBox(height: 20),
          pw.Text('Emplois',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _buildSimpleTable(emplois),
        ],
      ),
    );
    await Printing.layoutPdf(name: 'TAFIRE.pdf', onLayout: (format) async => doc.save());
  }

  /// Génère le PDF des Notes Annexes (liste de points textuels).
  static Future<void> exportNotesAnnexes({
    required List<String> notes,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text('Notes Annexes',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 16),
          ...notes.map((note) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Bullet(text: note),
          )),
        ],
      ),
    );
    await Printing.layoutPdf(
        name: 'Notes_Annexes.pdf', onLayout: (format) async => doc.save());
  }

  // --- Helpers de construction de tableaux PDF ---

  static pw.Widget _buildSimpleTable(List<Map<String, String>> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
      children: items.map((item) {
        return pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(6), child: pw.Text(item['label'] ?? '')),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(item['amount'] ?? '', textAlign: pw.TextAlign.right)),
        ]);
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
        ...rows.map((row) => pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${row['numero']}\n${row['libelle']}')),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['debit'] ?? '', textAlign: pw.TextAlign.right)),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['credit'] ?? '', textAlign: pw.TextAlign.right)),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text(row['solde'] ?? '', textAlign: pw.TextAlign.right)),
        ])),
      ],
    );
  }

  static pw.Widget _buildMouvementsTable(List<Map<String, dynamic>> mouvements) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(3),
        2: pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [_headerCell('Date'), _headerCell('Libellé'), _headerCell('Montant')],
        ),
        ...mouvements.map((m) => pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(6), child: pw.Text('${m['date'] ?? ''}')),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${m['libelle'] ?? ''}')),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child:
              pw.Text('${m['montant'] ?? ''}', textAlign: pw.TextAlign.right)),
        ])),
      ],
    );
  }

  static pw.Widget _buildEcritureLinesTable(List<Map<String, dynamic>> lines) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: const {0: pw.FlexColumnWidth(4), 1: pw.FlexColumnWidth(2)},
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [_headerCell('Compte'), _headerCell('Montant')],
        ),
        ...lines.map((l) => pw.TableRow(children: [
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${l['codeName'] ?? ''}')),
          pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('${l['amount'] ?? ''}', textAlign: pw.TextAlign.right)),
        ])),
      ],
    );
  }

  static pw.Widget _headerCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );
}