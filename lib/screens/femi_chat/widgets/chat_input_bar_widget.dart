import 'package:flutter/material.dart';

class ChatInputBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final Function(bool isCamera)? onPickImage;
  final VoidCallback? onMicToggle;
  final bool isRecording;

  const ChatInputBarWidget({
    super.key,
    required this.controller,
    required this.onSend,
    this.onPickImage,
    this.onMicToggle,
    this.isRecording = false,
  });

  // Affiche un menu bas pour choisir entre Prendre une photo ou Sélectionner dans la Galerie
  void _showAttachmentOptions(BuildContext context) {
    if (onPickImage == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionTile(
                  context,
                  icon: Icons.camera_alt_rounded,
                  label: 'Appareil photo',
                  color: const Color(0xFF006654),
                  onTap: () {
                    Navigator.pop(context);
                    onPickImage!(true); // true pour Caméra
                  },
                ),
                _buildOptionTile(
                  context,
                  icon: Icons.photo_library_rounded,
                  label: 'Galerie',
                  color: const Color(0xFF005AC1),
                  onTap: () {
                    Navigator.pop(context);
                    onPickImage!(false); // false pour Galerie
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isRecording ? Colors.red : Colors.grey.shade300,
          width: isRecording ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton pièce jointe (Photos / Reçus)
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.black54),
            onPressed: () => _showAttachmentOptions(context),
          ),

          // Zone de saisie texte
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              enabled: !isRecording,
              decoration: InputDecoration(
                hintText: isRecording
                    ? 'Enregistrement vocal en cours...'
                    : 'Demandez à Femi...',
                hintStyle: TextStyle(
                  color: isRecording ? Colors.red : Colors.grey.shade500,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          // Bouton Micro / Vocal (Devient rouge si on enregistre)
          IconButton(
            icon: Icon(
              isRecording ? Icons.stop_circle : Icons.mic_none_outlined,
              color: isRecording ? Colors.red : Colors.black54,
            ),
            onPressed: onMicToggle,
          ),

          // Bouton d'envoi principal
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF006654),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.arrow_upward,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onSend,
            ),
          ),
        ],
      ),
    );
  }
}