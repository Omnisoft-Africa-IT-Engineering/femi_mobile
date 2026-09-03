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
  });

  @override
  Widget build(BuildContext context) {
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
                  color: const Color(0xFFF0F4FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF0F172A), size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tagText,
                  style: const TextStyle(color: Color(0xFF0F9D58), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 10),
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