import 'package:flutter/material.dart';
import '../../../services/femi_api_service.dart';

class ChatHistoryItem {
  final String id;
  final String title;
  final String preview;
  final String dateLabel;
  final String? canal;

  const ChatHistoryItem({
    required this.id,
    required this.title,
    required this.preview,
    required this.dateLabel,
    this.canal,
  });
}

class ChatHistoryDrawerWidget extends StatefulWidget {
  final VoidCallback? onNouvelleConversation;
  final ValueChanged<ChatHistoryItem>? onSelectionnerConversation;

  const ChatHistoryDrawerWidget({
    super.key,
    this.onNouvelleConversation,
    this.onSelectionnerConversation,
  });

  @override
  State<ChatHistoryDrawerWidget> createState() =>
      _ChatHistoryDrawerWidgetState();
}

class _ChatHistoryDrawerWidgetState extends State<ChatHistoryDrawerWidget> {
  static const Color _primaryColor = Color(0xFF006654);

  final FemiApiService _api = FemiApiService();

  bool _loading = true;
  String? _error;
  List<ChatHistoryItem> _items = [];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final data = await _api.getConversations(limit: 30);

    if (!mounted) return;

    if (data == null) {
      setState(() {
        _loading = false;
        _error = 'Impossible de charger l\'historique.';
        _items = [];
      });
      return;
    }

    final results = (data['results'] as List?) ?? [];
    final mapped = <ChatHistoryItem>[];

    for (final raw in results) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);

      final id = m['id']?.toString() ?? '';
      if (id.isEmpty) continue;

      final apercu = (m['apercu']?.toString() ?? '').trim();
      final canal = m['canal_origine']?.toString();
      final nb = m['nb_messages'];
      final updated = m['updated_at']?.toString() ?? m['created_at']?.toString();

      mapped.add(
        ChatHistoryItem(
          id: id,
          title: apercu.isNotEmpty
              ? apercu
              : 'Conversation${nb != null ? ' ($nb msg)' : ''}',
          preview: [
            if (canal != null && canal.isNotEmpty) canal,
            if (nb != null) '$nb messages',
          ].join(' · '),
          dateLabel: _formatDateLabel(updated),
          canal: canal,
        ),
      );
    }

    setState(() {
      _loading = false;
      _items = mapped;
    });
  }

  String _formatDateLabel(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final day = DateTime(dt.year, dt.month, dt.day);
      final hm =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      if (day == today) return "Aujourd'hui, $hm";
      if (day == today.subtract(const Duration(days: 1))) {
        return 'Hier, $hm';
      }
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso.length >= 16 ? iso.substring(0, 16).replaceFirst('T', ' ') : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  const Icon(Icons.history, color: _primaryColor),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Historique',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.grey),
                    onPressed: _charger,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onNouvelleConversation?.call();
                  },
                  icon: const Icon(Icons.add, color: _primaryColor),
                  label: const Text(
                    'Nouvelle conversation',
                    style: TextStyle(
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_error!, textAlign: TextAlign.center),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _charger,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _items.isEmpty
                          ? const Center(
                              child: Text('Aucune conversation pour le moment.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => const Divider(
                                height: 1,
                                indent: 20,
                                endIndent: 20,
                              ),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFFE6F4F1),
                                    child: Icon(
                                      item.canal == 'WHATSAPP'
                                          ? Icons.chat
                                          : Icons.chat_bubble_outline,
                                      color: _primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    item.preview,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    item.dateLabel,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    widget.onSelectionnerConversation
                                        ?.call(item);
                                  },
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}