import 'package:flutter/material.dart';
import 'widgets/chat_date_badge_widget.dart';
import 'widgets/chat_input_bar_widget.dart';
import 'widgets/chat_message_bubble_widget.dart';

class FemiChatScreen extends StatefulWidget {
  const FemiChatScreen({super.key});

  @override
  State<FemiChatScreen> createState() => _FemiChatScreenState();
}

class _FemiChatScreenState extends State<FemiChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Utilisation directe de Map<String, dynamic> sans fichier de modèle
  final List<Map<String, dynamic>> _messages = [
    {
      'text': 'Bonjour ! Je suis Femi. Comment puis-je vous aider aujourd\'hui ?',
      'isUser': false,
      'time': '10:24',
    },
  ];

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final now = TimeOfDay.now();
    final timeString =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    setState(() {
      _messages.add({
        'text': text,
        'isUser': true,
        'time': timeString,
      });
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulation de réponse automatique de Femi
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'text':
              'J\'ai bien reçu votre message : "$text". Que souhaitez-vous faire ensuite ?',
          'isUser': false,
          'time': timeString,
        });
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
          ),
        ),
        title: const Text(
          'Femi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black87,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          const ChatDateBadgeWidget(dateText: 'Aujourd\'hui, 10:24'),
          const SizedBox(height: 12),

          // Zone des messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatMessageBubbleWidget(message: _messages[index]);
              },
            ),
          ),

          // Barre de saisie
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ChatInputBarWidget(
              controller: _messageController,
              onSend: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}