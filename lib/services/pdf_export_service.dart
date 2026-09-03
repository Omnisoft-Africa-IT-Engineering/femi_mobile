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

  static pw.Widget _headerCell(String text) => pw.Padding(
    padding: const pw.EdgeInsets.all(6),
    child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
  );
}