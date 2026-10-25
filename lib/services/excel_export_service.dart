import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';

/// Génération de fichiers Excel (.xlsx) pour les documents comptables.
class ExcelExportService {
  static const _mimeXlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  /// Génère le registre journalier en .xlsx et ouvre le partage / l'enregistrement.
  ///
  /// [ecritures] : chaque élément contient les clés `date`, `heure`, `titre`,
  /// `categorie`, `type` (libellé) et `montant` (double, toujours positif).
  static Future<void> exportRegistreJournalier({
    required String dateLabel,
    required String devise,
    required double totalRecettes,
    required double totalDepenses,
    required List<Map<String, dynamic>> ecritures,
  }) async {
    final excel = Excel.createExcel();
    final defaut = excel.getDefaultSheet();
    if (defaut != null) excel.rename(defaut, 'Registre');
    final feuille = excel['Registre'];

    final gras = CellStyle(bold: true);

    void ligne(List<CellValue?> cellules, {bool enGras = false}) {
      feuille.appendRow(cellules);
      if (!enGras) return;
      final rang = feuille.maxRows - 1;
      for (var c = 0; c < cellules.length; c++) {
        if (cellules[c] == null) continue;
        feuille
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: rang))
            .cellStyle = gras;
      }
    }

    ligne([TextCellValue('Registre journalier')], enGras: true);
    ligne([TextCellValue(dateLabel)]);
    ligne([]);
    ligne([
      TextCellValue('Total recettes ($devise)'),
      DoubleCellValue(totalRecettes),
    ]);
    ligne([
      TextCellValue('Total dépenses ($devise)'),
      DoubleCellValue(totalDepenses),
    ]);
    ligne([]);
    ligne([
      TextCellValue('Date'),
      TextCellValue('Heure'),
      TextCellValue('Titre'),
      TextCellValue('Catégorie'),
      TextCellValue('Type'),
      TextCellValue('Montant ($devise)'),
    ], enGras: true);

    for (final e in ecritures) {
      ligne([
        TextCellValue('${e['date'] ?? ''}'),
        TextCellValue('${e['heure'] ?? ''}'),
        TextCellValue('${e['titre'] ?? ''}'),
        TextCellValue('${e['categorie'] ?? ''}'),
        TextCellValue('${e['type'] ?? ''}'),
        DoubleCellValue((e['montant'] as num?)?.toDouble() ?? 0),
      ]);
    }

    const largeurs = [14.0, 10.0, 34.0, 20.0, 14.0, 18.0];
    for (var i = 0; i < largeurs.length; i++) {
      feuille.setColumnWidth(i, largeurs[i]);
    }

    final octets = excel.save();
    if (octets == null) {
      throw Exception("Impossible de générer le fichier Excel.");
    }

    final nom =
        'Registre_Journalier_${dateLabel.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')}.xlsx';

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            Uint8List.fromList(octets),
            mimeType: _mimeXlsx,
            name: nom,
          ),
        ],
        fileNameOverrides: [nom],
        subject: 'Registre journalier',
      ),
    );
  }
}