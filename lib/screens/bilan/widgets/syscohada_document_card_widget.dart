import 'package:flutter/material.dart';

class SyscohadaDocumentCardWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String tagText;
  final String subtitle;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String? footerNote;

  /// Quand false, les valeurs chiffrées ne sont pas affichées : la carte
  /// montre à la place un message indiquant que la donnée n'est pas
  /// encore calculable (ex. absence de module comptable dédié), plutôt
  /// que d'afficher des chiffres inventés.
  final bool isAvailable;

  const SyscohadaDocumentCardWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.tagText,
    required this.subtitle,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    this.footerNote,
    this.isAvailable = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconBgColor = isAvailable ? const Color(0xFFF0F4FA) : const Color(0xFFF1F5F9);
    final Color iconColor = isAvailable ? const Color(0xFF0F172A) : const Color(0xFF94A3B8);
    final Color tagBgColor = isAvailable ? const Color(0xFFE6F4EA) : const Color(0xFFF1F5F9);
    final Color tagTextColor = isAvailable ? const Color(0xFF0F9D58) : const Color(0xFF64748B);
    final String displayedTagText = isAvailable ? tagText : 'Indisponible';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tagBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayedTagText,
                  style: TextStyle(color: tagTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
          if (isAvailable)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(leftLabel, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text(leftValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rightLabel, style: const TextStyle(color: Colors.grey, fontSize: 9)),
                        const SizedBox(height: 2),
                        Text(rightValue, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Données incomplètes — module comptable requis',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          if (footerNote != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text(footerNote!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                const Spacer(),
                const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
              ],
            ),
          ],
        ],
      ),
    );
  }
}