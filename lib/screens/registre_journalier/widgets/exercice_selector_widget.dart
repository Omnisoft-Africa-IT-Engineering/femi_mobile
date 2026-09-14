import 'package:flutter/material.dart';

/// Sélecteur d'exercice comptable (année).
///
/// Affiche l'année actuellement sélectionnée avec un menu déroulant
/// permettant de choisir une autre année parmi une plage donnée.
class ExerciceSelectorWidget extends StatelessWidget {
  final int exerciceSelectionne;
  final int nombreAnneesAffichees;
  final ValueChanged<int> onExerciceChange;

  const ExerciceSelectorWidget({
    super.key,
    required this.exerciceSelectionne,
    required this.onExerciceChange,
    this.nombreAnneesAffichees = 6,
  });

  @override
  Widget build(BuildContext context) {
    final int anneeActuelle = DateTime.now().year;
    final List<int> annees = List.generate(
      nombreAnneesAffichees,
      (i) => anneeActuelle - i,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'Exercice',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: exerciceSelectionne,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0F172A)),
              borderRadius: BorderRadius.circular(12),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              items: annees
                  .map(
                    (annee) => DropdownMenuItem<int>(
                      value: annee,
                      child: Text(annee.toString()),
                    ),
                  )
                  .toList(),
              onChanged: (nouvelleAnnee) {
                if (nouvelleAnnee != null && nouvelleAnnee != exerciceSelectionne) {
                  onExerciceChange(nouvelleAnnee);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}