/// Formate un montant en FCFA : 110000 -> "110 000 FCFA"
String formatFcfa(num montant) {
  final s = montant.round().abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return '${montant < 0 ? '-' : ''}$buf FCFA';
}

/// Formate une date : 2026-09-28 -> "28/09/2026"
String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Formate une date et une heure : "28/09/2026 14:05"
String formatDateHeure(DateTime d) =>
    '${formatDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Formate une quantité de stock : 12.0 -> "12", 12.5 -> "12,5", 0.25 -> "0,25"
String formatQuantite(num q) {
  final texte = q
      .toStringAsFixed(3)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
  return texte.replaceAll('.', ',');
}
