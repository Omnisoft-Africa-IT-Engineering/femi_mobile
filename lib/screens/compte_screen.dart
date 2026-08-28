import 'package:flutter/material.dart';
// Importation du fichier d'état financier
import 'etat_financier_screen.dart'; 

class CompteScreen extends StatelessWidget {
  const CompteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Color(0xFFE1EBFD),
            child: Icon(Icons.person_outline, color: Color(0xFF1B75BC)),
          ),
        ),
        title: const Text('Comptes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          // CORRECTION ICI: CrossAxisAlignment au lieu de CrossAlignment
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Documents Comptables', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 12),
            
            // Redirection vers le Bilan Comptable SYSCOHADA
            _buildDocCard(
              context,
              Icons.description_outlined,
              'État financier',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BilanSyscohadaScreen()),
                );
              },
            ),
            _buildDocCard(context, Icons.menu_book_outlined, 'Grand livre'),
            _buildDocCard(
              context,
              Icons.account_balance_outlined,
              'Bilan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BilanSyscohadaScreen()),
                );
              },
            ),
            _buildDocCard(context, Icons.balance_outlined, 'Balance'),
            
            const SizedBox(height: 24),
            const Text('Paramètres du Profil', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.black87),
                title: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
                trailing: const Icon(Icons.exit_to_app, color: Colors.black54),
                onTap: () {},
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAF0F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: ListTile(
                title: const Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                trailing: const Icon(Icons.delete_outline, color: Colors.red),
                onTap: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocCard(BuildContext context, IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF1B75BC)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}