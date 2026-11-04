import 'package:flutter/material.dart';

import '../../../models/produit.dart';
import '../../../services/stock_service.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/format.dart';
import '../../stock/stock_screen.dart';

/// Produits à surveiller (ruptures puis sous le seuil d'alerte).
class AlertesStock {
  final int nbRuptures;
  final int nbAlertes;
  final List<Produit> produits; // les plus urgents, 3 au maximum

  /// Produits actifs sans seuil d'alerte (donc jamais surveillés).
  final int sansSeuil;

  const AlertesStock({
    required this.nbRuptures,
    required this.nbAlertes,
    required this.produits,
    this.sansSeuil = 0,
  });

  bool get aSurveiller => nbRuptures + nbAlertes > 0;

  /// Retourne null si le stock est illisible (réseau, compte sans entreprise) :
  /// le dashboard n'affiche alors simplement aucune alerte.
  static Future<AlertesStock?> charger() async {
    try {
      final service = StockService.instance;
      final ResumeStock resume = await service.resume();
      if (resume.nbRuptures + resume.nbAlertes == 0) {
        // Rien à signaler : on regarde si des produits ne sont pas surveillés
        // (seuil d'alerte à 0), car sans seuil aucune alerte ne peut se produire.
        int sansSeuil = 0;
        if (resume.nombreProduits > 0) {
          final tous = await service.listerProduits();
          sansSeuil = tous.where((p) => p.seuilAlerte <= 0).length;
        }
        return AlertesStock(
          nbRuptures: 0,
          nbAlertes: 0,
          produits: const [],
          sansSeuil: sansSeuil,
        );
      }

      final listes = await Future.wait([
        resume.nbRuptures > 0
            ? service.listerProduits(statut: 'RUPTURE')
            : Future.value(<Produit>[]),
        resume.nbAlertes > 0
            ? service.listerProduits(statut: 'ALERTE')
            : Future.value(<Produit>[]),
      ]);

      return AlertesStock(
        nbRuptures: resume.nbRuptures,
        nbAlertes: resume.nbAlertes,
        produits: [...listes[0], ...listes[1]].take(3).toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Bandeau d'alerte stock du dashboard. Invisible quand il n'y a rien à signaler.
class StockAlertBanner extends StatelessWidget {
  final Future<AlertesStock?> future;
  final VoidCallback? onRetourStock;

  const StockAlertBanner({
    super.key,
    required this.future,
    this.onRetourStock,
  });

  /// Aucun produit en alerte, mais des produits sans seuil : on guide l'utilisateur.
  Widget _buildAideSeuil(BuildContext context, int nombre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.vertClair,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const StockScreen()),
            );
            onRetourStock?.call();
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined,
                    color: AppColors.vert, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nombre == 1
                        ? "1 produit n'a pas de seuil d'alerte. Définis-en un pour être prévenu avant la rupture."
                        : "$nombre produits n'ont pas de seuil d'alerte. Définis-en un pour être prévenu avant la rupture.",
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.vert,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.vert),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AlertesStock?>(
      future: future,
      builder: (context, snapshot) {
        final AlertesStock? alertes = snapshot.data;
        if (alertes == null) return const SizedBox.shrink();
        if (!alertes.aSurveiller) {
          return alertes.sansSeuil > 0
              ? _buildAideSeuil(context, alertes.sansSeuil)
              : const SizedBox.shrink();
        }

        final bool rupture = alertes.nbRuptures > 0;
        final Color couleur = rupture ? Colors.red : Colors.orange.shade800;

        final List<String> resume = [
          if (alertes.nbRuptures > 0)
            '${alertes.nbRuptures} en rupture',
          if (alertes.nbAlertes > 0)
            '${alertes.nbAlertes} sous le seuil d\'alerte',
        ];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Material(
            color: couleur.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StockScreen()),
                );
                onRetourStock?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: couleur.withValues(alpha: 0.35)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            color: couleur, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Alerte stock : ${resume.join(' · ')}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: couleur,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: couleur),
                      ],
                    ),
                    if (alertes.produits.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      for (final Produit p in alertes.produits)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            p.stockActuel <= 0
                                ? '• ${p.nom} — rupture'
                                : '• ${p.nom} — ${formatQuantite(p.stockActuel)} ${p.unite} restant(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade800,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
