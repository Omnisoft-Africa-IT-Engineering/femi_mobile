import 'package:flutter/material.dart';

class TargetFeatureBannerWidget extends StatelessWidget {
  final String targetFeature;

  const TargetFeatureBannerWidget({
    super.key,
    required this.targetFeature,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Abonnez-vous au plan Pro pour débloquer "$targetFeature".',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}