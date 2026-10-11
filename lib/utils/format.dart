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