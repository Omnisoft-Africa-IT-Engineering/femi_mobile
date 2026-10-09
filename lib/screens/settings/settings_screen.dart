import 'package:flutter/material.dart';
import 'team_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF0D5C52);
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.groups_outlined, color: primary),
            title: const Text('Mon équipe'),
            subtitle: const Text('Ajouter vos employés et suivre leur activité'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TeamScreen()),
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}