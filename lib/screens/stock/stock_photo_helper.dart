import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/stock_service.dart';
import '../../theme/app_colors.dart';

/// Ouvre la caméra / galerie, appelle l'OCR stock, renvoie la 1re ligne lue
/// ou null si annulé / échec.
///
/// Clés utiles du map renvoyé :
/// - nom, quantite, cout_unitaire, prix_vente, sku, unite
/// - produit_existant_id, stock_actuel
/// - type_suggere (ENTREE | SORTIE | …)
Future<Map<String, dynamic>?> capturerEtLireStock(BuildContext context) async {
  final picker = ImagePicker();
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final fichier = await picker.pickImage(source: source, imageQuality: 85);
  if (fichier == null) return null;

  if (!context.mounted) return null;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.vert),
              SizedBox(height: 16),
              Text('Lecture de la photo…'),
            ],
          ),
        ),
      ),
    ),
  );

  try {
    final octets = await fichier.readAsBytes();
    final data = await StockService.instance.ocrPreview(
      octets: octets,
      nomFichier: fichier.name,
    );
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    final lignes = data['lignes'];
    if (lignes is! List || lignes.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun produit lisible sur cette photo.')),
        );
      }
      return null;
    }
    final ligne = Map<String, dynamic>.from(lignes.first as Map);
    ligne['type_suggere'] = data['type_suggere'];
    return ligne;
  } catch (e) {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
    return null;
  }
}
