import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
class MetricCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  /// Emoji du catalogue KPI (ex. 💰). S'il est fourni, il remplace l'icône.
  final String? emoji;

  /// Couleur de la valeur (noir par défaut ; rouge pour un chiffre négatif).
  final Color valueColor;

  const MetricCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.icon = Icons.analytics_outlined,
    this.color = AppColors.vert,
    this.subtitle,
    this.emoji,
    this.valueColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    final bool aEmoji = emoji != null && emoji!.trim().isNotEmpty;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (aEmoji)
                Text(emoji!, style: const TextStyle(fontSize: 14))
              else
                Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
