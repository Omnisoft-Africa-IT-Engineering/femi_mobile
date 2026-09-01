import 'package:flutter/material.dart';

class ChatDateBadgeWidget extends StatelessWidget {
  final String dateText;

  const ChatDateBadgeWidget({
    super.key,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEBF2FA),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        dateText,
        style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
      ),
    );
  }
}