import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/produit.dart';
import '../../services/stock_service.dart';
import '../../theme/app_colors.dart';

/// Import de produits depuis un fichier Excel (.xlsx).
class ImportProduitsScreen extends StatefulWidget {
  const ImportProduitsScreen({super.key});

  @override
  State<ImportProduitsScreen> createState() => _ImportProduitsScreenState();
}

class _ImportProduitsScreenState extends State<ImportProduitsScreen> {
  static const _mimeXlsx =
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';

  final _service = StockService.instance;
  bool _enCours = false;
  RapportImport? _rapport;
  String? _erreur;

  Future<void> _telechargerModele() async {
    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      final octets = await _service.telechargerModele();
      const nom = 'modele_import_produits.xlsx';
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(Uint8List.fromList(octets), mimeType: _mimeXlsx, name: nom),
          ],
          fileNameOverrides: const [nom],
          subject: 'Modèle d\'import de produits',
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  Future<void> _choisirFichier() async {
    setState(() {
      _erreur = null;
      _rapport = null;
    });
    try {
      final resultat = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        withData: true,
      );
      if (resultat == null || resultat.files.isEmpty) return;

      final fichier = resultat.files.single;
      final octets = fichier.bytes;
      if (octets == null) {
        setState(() => _erreur = 'Impossible de lire ce fichier.');
        return;
      }

      setState(() => _enCours = true);
      final rapport = await _service.importerProduits(
        octets: octets,
        nomFichier: fichier.name,
      );
      if (mounted) setState(() => _rapport = rapport);
    } catch (e) {
      if (mounted) {
        setState(() => _erreur = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _enCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondEcran,
      appBar: AppBar(title: const Text('Importer des produits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _etape(
            1,
            'Téléchargez le modèle',
            'Un fichier Excel avec les bonnes colonnes : nom, unité, prix de '
                'vente, prix d\'achat, stock initial, seuil d\'alerte et code '
                'article. Seul le nom est obligatoire.',
            OutlinedButton.icon(
              onPressed: _enCours ? null : _telechargerModele,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Télécharger le modèle'),
            ),
          ),
          const SizedBox(height: 12),
          _etape(
            2,
            'Remplissez-le',
            'Une ligne par produit. Indiquez le stock réellement présent '
                'aujourd\'hui : il devient votre stock de départ. Les produits '
                'déjà existants (même nom) sont ignorés, jamais écrasés.',
            null,
          ),
          const SizedBox(height: 12),
          _etape(
            3,
            'Envoyez votre fichier',
            'Choisissez le fichier .xlsx rempli. Les lignes valides sont '
                'importées, et celles qui posent problème sont listées.',
            ElevatedButton.icon(
              onPressed: _enCours ? null : _choisirFichier,
              icon: _enCours
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.upload_file_outlined),
              label: const Text('Choisir mon fichier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vert,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          if (_erreur != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_erreur!,
                  style: const TextStyle(color: Color(0xFFB91C1C))),
            ),
          ],
          if (_rapport != null) ...[
            const SizedBox(height: 16),
            _resultat(_rapport!),
          ],
        ],
      ),
    );
  }

  Widget _etape(int numero, String titre, String texte, Widget? action) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.vertClair,
            child: Text('$numero',
                style: const TextStyle(
                    color: AppColors.vert, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.encre)),
                const SizedBox(height: 4),
                Text(texte,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.ardoise)),
                if (action != null) ...[
                  const SizedBox(height: 10),
                  action,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultat(RapportImport r) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            r.crees == 1 ? '1 produit importé' : '${r.crees} produits importés',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.vert),
          ),
          Text('sur ${r.totalLignes} ligne(s) lue(s)',
              style: const TextStyle(color: AppColors.ardoise)),
          if (r.ignores.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '${r.ignores.length} ligne(s) ignorée(s)',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 6),
            ...r.ignores.map(
              (l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Text(
                  'Ligne ${l.ligne}${l.nom.isNotEmpty ? ' (${l.nom})' : ''} : ${l.erreur}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.ardoiseFoncee),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Corrigez ces lignes dans votre fichier puis importez-le à '
              'nouveau : les produits déjà importés seront ignorés.',
              style: TextStyle(fontSize: 12, color: AppColors.ardoise),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.vert,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voir mon stock'),
            ),
          ),
        ],
      ),
    );
  }
}
