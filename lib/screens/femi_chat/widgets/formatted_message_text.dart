import 'package:flutter/material.dart';

import '../../../utils/rich_message.dart';

/// Affiche une réponse de Femi bien structurée :
///  - une ligne « • », « - » ou « * » devient une puce avec retrait ;
///  - une ligne « 1. » devient une liste numérotée ;
///  - une ligne « # Titre » devient un titre en gras ;
///  - les lignes vides sont de vrais espaces entre les blocs ;
///  - **gras**, *gras* et les montants (voir rich_message.dart) sont mis en gras.
class FormattedMessageText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool grasAutomatique;

  const FormattedMessageText({
    super.key,
    required this.text,
    required this.style,
    this.grasAutomatique = true,
  });

  static final RegExp _puce = RegExp(r'^\s*(?:[-*•–])\s+(.*)$');
  static final RegExp _numero = RegExp(r'^\s*(\d{1,2})[.)]\s+(.*)$');
  static final RegExp _titre = RegExp(r'^\s*#{1,6}\s+(.*)$');

  @override
  Widget build(BuildContext context) {
    final List<Widget> blocs = [];
    bool precedentVide = true; // évite les espaces en début de message

    for (final String ligne in text.trim().split('\n')) {
      final String nette = ligne.trimRight();

      if (nette.trim().isEmpty) {
        if (!precedentVide) blocs.add(const SizedBox(height: 8));
        precedentVide = true;
        continue;
      }
      precedentVide = false;

      final RegExpMatch? titre = _titre.firstMatch(nette);
      final RegExpMatch? puce = _puce.firstMatch(nette);
      final RegExpMatch? numero = _numero.firstMatch(nette);

      if (titre != null) {
        blocs.add(Padding(
          padding: const EdgeInsets.only(top: 2, bottom: 2),
          child: Text(
            titre.group(1)!,
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ));
      } else if (puce != null) {
        blocs.add(_ligneListe('•', puce.group(1)!));
      } else if (numero != null) {
        blocs.add(_ligneListe('${numero.group(1)}.', numero.group(2)!));
      } else {
        blocs.add(_paragraphe(nette));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocs,
    );
  }

  Widget _paragraphe(String contenu) {
    return Text.rich(
      TextSpan(
        children: construireSpansMessage(
          contenu,
          style: style,
          grasAutomatique: grasAutomatique,
        ),
      ),
    );
  }

  Widget _ligneListe(String marqueur, String contenu) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: marqueur.length > 2 ? 26 : 18,
            child: Text(marqueur, style: style),
          ),
          Expanded(child: _paragraphe(contenu)),
        ],
      ),
    );
  }
}
