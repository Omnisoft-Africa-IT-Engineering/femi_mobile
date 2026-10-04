import 'package:flutter/material.dart';

/// Représente une conversation passée dans l'historique.
/// TODO: remplacer par le modèle réel une fois l'endpoint d'historique
/// disponible (probablement id, titre, dernier message, date/heure...).
class ChatHistoryItem {
  final String title;
  final String preview;
  final String dateLabel;

  const ChatHistoryItem({
    required this.title,
    required this.preview,
    required this.dateLabel,
  });
}

/// Drawer affichant l'historique des discussions avec Femi.
/// DONNÉES STATIQUES pour l'instant — l'endpoint backend n'est pas encore
/// prêt. À remplacer par un vrai chargement (FutureBuilder / service API)
/// dès qu'il sera disponible, en gardant la même structure visuelle.
class ChatHistoryDrawerWidget extends StatelessWidget {
  /// Appelé quand l'utilisateur tape sur "Nouvelle conversation".
  final VoidCallback? onNouvelleConversation;

  /// Appelé quand l'utilisateur tape sur une conversation de l'historique.
  /// Reçoit l'item sélectionné (pour l'instant, sans effet réel puisque
  /// les données sont statiques).
  final ValueChanged<ChatHistoryItem>? onSelectionnerConversation;

  const ChatHistoryDrawerWidget({
    super.key,
    this.onNouvelleConversation,
    this.onSelectionnerConversation,
  });

  // Données factices, à remplacer par l'API plus tard.
  static const List<ChatHistoryItem> _historiqueStatique = [
    ChatHistoryItem(
      title: 'Vente de riz - 5 sacs',
      preview: 'Femi : Transaction enregistrée avec succès ✅',
      dateLabel: "Aujourd'hui, 09:15",
    ),
    ChatHistoryItem(
      title: 'Dépense carburant',
      preview: 'Vous : combien j\'ai dépensé ce mois-ci en carburant ?',
      dateLabel: 'Hier, 18:42',
    ),
    ChatHistoryItem(
      title: 'Rapport hebdomadaire',
      preview: 'Femi : Voici le résumé de votre semaine...',
      dateLabel: 'Hier, 08:03',
    ),
    ChatHistoryItem(
      title: 'Achat de marchandises',
      preview: 'Vous : j\'ai acheté pour 45000 FCFA de stock',
      dateLabel: '15 sept.',
    ),
    ChatHistoryItem(
      title: 'Question sur mon abonnement',
      preview: 'Femi : Vous êtes actuellement sur la formule Pro',
      dateLabel: '12 sept.',
    ),
  ];

  static const Color _primaryColor = Color(0xFF006654);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- En-tête ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: _primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Historique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // --- Bouton "Nouvelle conversation" ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(); // ferme le drawer
                    onNouvelleConversation?.call();
                  },
                  icon: const Icon(Icons.add, color: _primaryColor),
                  label: const Text(
                    'Nouvelle conversation',
                    style: TextStyle(color: _primaryColor, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // --- Liste de l'historique (statique) ---
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _historiqueStatique.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final item = _historiqueStatique[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE6F4F1),
                      child: Icon(Icons.chat_bubble_outline, color: _primaryColor, size: 20),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      item.preview,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      item.dateLabel,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                    onTap: () {
                      Navigator.of(context).pop(); // ferme le drawer
                      onSelectionnerConversation?.call(item);
                    },
                  );
                },
              ),
            ),

            // --- Petit rappel visuel que c'est temporaire ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Historique temporaire — bientôt synchronisé avec vos vraies conversations.',
                style: TextStyle(fontSize: 11, color: Colors.grey[400], fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}