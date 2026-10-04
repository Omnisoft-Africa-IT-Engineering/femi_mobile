import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/femi_agent_models.dart';

class ChatMessageBubbleWidget extends StatelessWidget {
  final Map<String, dynamic> message;

  const ChatMessageBubbleWidget({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = (message['isUser'] as bool?) ?? false;
    final text = message['text'] as String?;
    final time = (message['time'] as String?) ?? '';
    final imageFile = message['imageFile'] as File?;
    final audioFile = message['audioFile'] as File?;
    final transaction = message['transaction'] as FemiTransaction?;

    // Si le message contient une transaction de FemiAgent (Code 201)
    if (transaction != null) {
      return _buildTransactionCard(context, transaction, time);
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF006654) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Affichage de l'image jointe
            if (imageFile != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Affichage du message vocal
            if (audioFile != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: isUser ? Colors.white : const Color(0xFF006654),
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Message vocal',
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],

            // Texte du message
            if (text != null && text.isNotEmpty)
              Text(
                text,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),

            const SizedBox(height: 4),

            // Horodatage
            Text(
              time,
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte visuelle structurée pour les transactions enregistrées
  Widget _buildTransactionCard(
      BuildContext context, FemiTransaction tx, String time) {
    final isRecette = tx.transactionType.toUpperCase() == 'RECETTE';
    final accentColor = isRecette ? const Color(0xFF16A34A) : const Color(0xFFEA580C);

    // Sécurisation de la conversion du montant en double pour l'affichage
    final double amount = double.tryParse(tx.amountTtc.toString()) ?? 0.0;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        width: MediaQuery.of(context).size.width * 0.82,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accentColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge & Montant
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tx.transactionType,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${amount.toStringAsFixed(0)} ${tx.currency}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800, // <--- Modifié (w800 au lieu de extrabold)
                    fontSize: 17,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description
            Text(
              tx.description,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 6),

            // Détails (Catégorie & Méthode de paiement)
            Row(
              children: [
                Icon(Icons.category_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  tx.category,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Icon(Icons.payment_outlined,
                    size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  tx.paymentMethod,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.8),
            ),

            // Footer (Statut & Heure)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: Color(0xFF16A34A), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Enregistrée (${(tx.confidenceScore * 100).toInt()}% conf.)',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}