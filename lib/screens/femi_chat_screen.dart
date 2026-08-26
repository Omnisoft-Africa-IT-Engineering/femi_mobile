import 'package:flutter/material.dart';

class FemiChatScreen extends StatelessWidget {
  const FemiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundImage: NetworkImage('https://i.pravatar.cc/100?img=5'),
          ),
        ),
        title: const Text('Femi', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEBF2FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Aujourd\'hui, 10:24', style: TextStyle(fontSize: 12, color: Colors.blueGrey)),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.black54),
                    onPressed: () {},
                  ),
                  const Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Demandez à Femi...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic_none_outlined, color: Colors.black54),
                    onPressed: () {},
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF006654),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}