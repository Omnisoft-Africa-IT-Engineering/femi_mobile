/// Décode les entités HTML qui s'affichent en clair dans certaines réponses
/// (« l&apos;assistant » -> « l'assistant », « comptabilit&eacute; » ->
/// « comptabilité », « &#128522; » -> 😊). Un seul passage : « &amp;eacute; »
/// devient « &eacute; » et pas « é ». Les entités inconnues restent telles quelles.
String decoderEntitesHtml(String texte) {
  if (!texte.contains('&')) return texte;

  return texte.replaceAllMapped(
    RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z][a-zA-Z0-9]*);'),
    (match) {
      final String code = match.group(1)!;

      if (code.startsWith('#')) {
        final bool hexa = code.length > 1 && (code[1] == 'x' || code[1] == 'X');
        final int? point = int.tryParse(
          code.substring(hexa ? 2 : 1),
          radix: hexa ? 16 : 10,
        );
        if (point == null || point <= 0 || point > 0x10FFFF) {
          return match.group(0)!;
        }
        return String.fromCharCode(point);
      }

      return _entitesNommees[code] ?? match.group(0)!;
    },
  );
}

const Map<String, String> _entitesNommees = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00A0',
  'laquo': '«',
  'raquo': '»',
  'lsquo': '‘',
  'rsquo': '’',
  'ldquo': '“',
  'rdquo': '”',
  'hellip': '…',
  'ndash': '–',
  'mdash': '—',
  'bull': '•',
  'middot': '·',
  'deg': '°',
  'times': '×',
  'euro': '€',
  'copy': '©',
  'agrave': 'à',
  'aacute': 'á',
  'acirc': 'â',
  'auml': 'ä',
  'ccedil': 'ç',
  'egrave': 'è',
  'eacute': 'é',
  'ecirc': 'ê',
  'euml': 'ë',
  'igrave': 'ì',
  'iacute': 'í',
  'icirc': 'î',
  'iuml': 'ï',
  'ograve': 'ò',
  'oacute': 'ó',
  'ocirc': 'ô',
  'ouml': 'ö',
  'ugrave': 'ù',
  'uacute': 'ú',
  'ucirc': 'û',
  'uuml': 'ü',
  'yuml': 'ÿ',
  'oelig': 'œ',
  'Agrave': 'À',
  'Acirc': 'Â',
  'Ccedil': 'Ç',
  'Egrave': 'È',
  'Eacute': 'É',
  'Ecirc': 'Ê',
  'Euml': 'Ë',
  'Icirc': 'Î',
  'Iuml': 'Ï',
  'Ocirc': 'Ô',
  'Ugrave': 'Ù',
  'Ucirc': 'Û',
  'Uuml': 'Ü',
  'OElig': 'Œ',
};
