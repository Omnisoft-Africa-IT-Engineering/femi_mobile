import 'package:flutter/material.dart';

/// Met en forme une réponse de Femi :
///  - **texte** et *texte* (style Markdown / WhatsApp) deviennent du gras ;
///  - les montants (« 5 000 FCFA », « 4,320 FCFA ») et les pourcentages
///    (« 12,5 % ») sont automatiquement mis en gras.
/// Les marqueurs ne sont jamais affichés. Un marqueur non fermé reste tel quel.
List<InlineSpan> construireSpansMessage(
  String texte, {
  required TextStyle style,
  bool grasAutomatique = true,
}) {
  final TextStyle gras = style.copyWith(fontWeight: FontWeight.w700);
  final List<InlineSpan> spans = [];

  int curseur = 0;
  for (final RegExpMatch m in _marqueurGras.allMatches(texte)) {
    if (m.start > curseur) {
      spans.addAll(_segmentSimple(
        texte.substring(curseur, m.start),
        style,
        gras,
        grasAutomatique,
      ));
    }
    final String contenu = m.group(1) ?? m.group(2) ?? '';
    spans.add(TextSpan(text: contenu, style: gras));
    curseur = m.end;
  }
  if (curseur < texte.length) {
    spans.addAll(_segmentSimple(
      texte.substring(curseur),
      style,
      gras,
      grasAutomatique,
    ));
  }
  return spans;
}

// **gras**  ou  *gras*  (le simple astérisque ne doit pas toucher un mot ni
// servir de puce « * item »).
final RegExp _marqueurGras = RegExp(
  r'\*\*([^*\n]+?)\*\*|(?<![\w*])\*([^\s*][^*\n]*?)\*(?![\w*])',
);

// Montants en francs CFA et pourcentages.
final RegExp _montant = RegExp(
  r'(?<![\w.,])-?\d+(?:[\s\u00A0.,]\d{3})*(?:[.,]\d+)?[\s\u00A0]?(?:FCFA|F CFA|XOF)(?!\w)'
  r'|(?<![\w.,])\d+(?:[.,]\d+)?[\s\u00A0]?%',
);

List<InlineSpan> _segmentSimple(
  String segment,
  TextStyle normal,
  TextStyle gras,
  bool grasAutomatique,
) {
  if (!grasAutomatique) return [TextSpan(text: segment, style: normal)];

  final List<InlineSpan> spans = [];
  int curseur = 0;
  for (final RegExpMatch m in _montant.allMatches(segment)) {
    if (m.start > curseur) {
      spans.add(TextSpan(
        text: segment.substring(curseur, m.start),
        style: normal,
      ));
    }
    spans.add(TextSpan(text: m.group(0), style: gras));
    curseur = m.end;
  }
  if (curseur < segment.length) {
    spans.add(TextSpan(text: segment.substring(curseur), style: normal));
  }
  return spans;
}
