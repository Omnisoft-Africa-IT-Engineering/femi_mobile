import 'package:flutter/material.dart';
import 'widgets/faq_header.dart';
import 'widgets/faq_card.dart';
import 'widgets/faq_contact_card.dart';
import '../femi_chat/femi_chat_screen.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  static const List<Map<String, String>> _faqItems = [
    {
      'number': '1',
      'question': 'Comment envoyer mes reçus à Femi ?',
      'answer':
          'Envoyez simplement une photo, une note vocale ou un texte directement sur WhatsApp. Femi s\'occupe de l\'enregistrement comptable.',
    },
    {
      'number': '2',
      'question':
          'Mes données et états financiers sont-ils conformes SYSCOHADA ?',
      'answer':
          'Oui, toutes les écritures respectent scrupuleusement les normes de l\'OHADA / SYSCOHADA révisé pour vos liasses fiscales.',
    },
    {
      'number': '3',
      'question': 'Puis-je corriger une écriture enregistrée ?',
      'answer':
          'Oui, dites simplement à Femi sur WhatsApp ou dans l\'application de modifier le montant ou la catégorie.',
    },
    {
      'number': '4',
      'question': 'Comment exporter mon bilan ou grand livre ?',
      'answer':
          'Rendez-vous dans l\'onglet « Compte » et cliquez sur « Télécharger la Liasse Fiscale » au format PDF ou Excel.',
    },
    {
      'number': '5',
      'question': 'Le service est-il disponible 24h/24 ?',
      'answer':
          'Oui, Femi traite vos pièces comptables instantanément, de jour comme de nuit.',
    },
  ];

  // Ouvre l'écran de chat interne avec Femi.
  void _ouvrirChatFemi(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FemiChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FD),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FaqHeader(),
              const SizedBox(height: 24),

              // Liste des cartes FAQ
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _faqItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final item = _faqItems[index];
                  return FaqCard(
                    number: item['number']!,
                    question: item['question']!,
                    answer: item['answer']!,
                  );
                },
              ),

              const SizedBox(height: 20),

              // Carte d'action bas de page
              FaqContactCard(
                onPressed: () => _ouvrirChatFemi(context),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}