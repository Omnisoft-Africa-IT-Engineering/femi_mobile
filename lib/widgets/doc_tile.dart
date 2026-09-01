import 'package:flutter/material.dart';

class DocTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isProFeature;
  final bool isUserPro;
  final VoidCallback onTap;

  const DocTile({
    super.key,
    required this.icon,
    required this.title,
    this.isProFeature = false,
    required this.isUserPro,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLocked = isProFeature && !isUserPro;

    return ListTile(
      leading: Icon(icon, color: const Color(0xFF1B75BC)),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (isLocked) ...[
            const SizedBox(width: 8),
            const Chip(
              label: Text('PRO', style: TextStyle(fontSize: 10, color: Colors.orange)),
              backgroundColor: Color(0xFFFEF3C7),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ],
      ),
      trailing: Icon(isLocked ? Icons.lock_outline : Icons.chevron_right),
      onTap: onTap,
    );
  }
}