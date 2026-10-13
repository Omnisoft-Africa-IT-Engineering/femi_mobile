import 'package:flutter/material.dart';

/// Couleurs de la charte graphique Femi (version 1.0).
/// À utiliser partout dans l'app à la place des valeurs écrites en dur.
class AppColors {
  AppColors._();

  // --- Principales ---
  /// Vert Femi profond : boutons, titres, icônes sur fond clair.
  static const Color vert = Color(0xFF0D5C52);

  /// Émeraude : accent du logo, à utiliser sur fond sombre.
  static const Color emeraude = Color(0xFF2CD19F);

  /// Bleu Omnisoft : signature Omnisoft et accents (pas de texte blanc dessus).
  static const Color bleuOmnisoft = Color(0xFF19A0E0);

  // --- Fonds ---
  /// Nuit : fond du logo, écran de démarrage, icône.
  static const Color nuit = Color(0xFF0B1F1C);

  /// Vert très clair : cartes de chiffres, ligne sélectionnée.
  static const Color vertClair = Color(0xFFEAF6F3);

  /// Fond d'écran de l'application.
  static const Color fondEcran = Color(0xFFF8F9FE);

  // --- Textes et lignes ---
  static const Color encre = Color(0xFF0F172A);
  static const Color ardoise = Color(0xFF64748B);
  static const Color bordure = Color(0xFFE2E8F0);

  /// Gris foncé : textes secondaires un peu plus marqués.
  static const Color ardoiseFoncee = Color(0xFF475569);

  /// Gris clair : icônes et textes discrets.
  static const Color gris = Color(0xFF94A3B8);

  /// Fond gris très clair (zones neutres, pastilles).
  static const Color fondGris = Color(0xFFF1F5F9);

  /// Fond bleu très clair (bandeaux et cartes d'information).
  static const Color bleuClair = Color(0xFFEAF2FF);

  // --- Fonctionnelles ---
  /// Ventes et entrées d'argent.
  static const Color recette = Color(0xFF059669);

  /// Dépenses et sorties d'argent.
  static const Color depense = Color(0xFFDC2626);

  /// Prêts reçus, carte FAQ, assistance, liens et boutons bleus.
  /// (Le prêt donné utilise [vert].)
  static const Color bleuAction = Color(0xFF1B75BC);

  // --- Badge PRO ---
  static const Color proFond = Color(0xFFFFF0C2);
  static const Color proBordure = Color(0xFFE6C36A);
  static const Color proTexte = Color(0xFF8A5600);
}