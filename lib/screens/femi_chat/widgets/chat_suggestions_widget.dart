import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Questions rapides affichées au-dessus du champ de saisie. Un appui envoie
/// directement la question. Les suggestions disparaissent dès que l'utilisateur
/// commence à écrire, ou pendant un envoi / un enregistrement vocal.
class ChatSuggestionsWidget extends StatelessWidget {
  final TextEditingController controller;
  final bool visible;
  final ValueChanged<String> onSelect;

  const ChatSuggestionsWidget({
    super.key,
    required this.controller,
    required this.visible,
    required this.onSelect,
  });

  static const List<String> suggestions = [
    "Mon chiffre d'affaires du mois",
    'Mes dépenses du mois',
    'Mon bénéfice du mois',
    'Qui me doit de l\'argent ?',
    'Produits en rupture ou en alerte',
  ];

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (value.text.trim().isNotEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            itemCount: suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final String question = suggestions[index];
              return Material(
                color: Colors.white,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: AppColors.vert.withValues(alpha: 0.35),
                  ),
                ),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => onSelect(question),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Center(
                      child: Text(
                        question,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.vert,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
